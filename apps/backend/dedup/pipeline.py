"""3단계 중복 제거 파이프라인 (참조 구현).

단계는 싼 체부터 차례로 적용한다 (설계서 4-1장):
  1. exact_hash   — 정규화 본문의 SHA-256 완전 일치
  2. minhash_lsh  — MinHash 서명 + LSH 버킷으로 후보를 좁힌 뒤 자카드 유사도 검증
  3. semantic     — 외부 임베딩(다국어)을 꽂아 코사인 유사도로 병합. 임베더가 없으면 생략

전수 비교를 피하기 위해 블로킹(issuer + 발행 시각 윈도)을 먼저 적용한다.
결과의 (match_method, confidence)는 event_evidence 테이블 컬럼에 대응한다.
"""

from __future__ import annotations

import hashlib
import math
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Callable, Iterable, Optional, Protocol, Sequence

# ---------------------------------------------------------------------------
# 입출력 타입
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Item:
    """normalized_item 1건에 대응하는 입력."""

    id: int
    title: str
    body: str = ""
    issuer_id: Optional[int] = None
    published_at: Optional[datetime] = None
    language: str = "en"

    @property
    def text(self) -> str:
        return f"{self.title}\n{self.body}".strip()


@dataclass(frozen=True)
class Match:
    """두 기사가 같은 사건이라는 판정 1건."""

    item_a: int
    item_b: int
    method: str  # exact_hash | minhash_lsh | semantic
    confidence: float


@dataclass
class Cluster:
    """같은 사건으로 묶인 기사 집합 (canonical_event 1개 후보)."""

    member_ids: list[int] = field(default_factory=list)
    matches: list[Match] = field(default_factory=list)

    @property
    def duplicates_removed(self) -> int:
        return max(0, len(self.member_ids) - 1)


class Embedder(Protocol):
    """3단계용 다국어 임베딩 인터페이스. 백엔드에서 실제 모델로 교체한다."""

    def embed(self, text: str) -> Sequence[float]: ...


# ---------------------------------------------------------------------------
# 텍스트 정규화 / 1단계: 완전 일치
# ---------------------------------------------------------------------------

_WS_RE = re.compile(r"\s+")
_PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)


def normalize_text(text: str) -> str:
    """대소문자·구두점·공백 차이를 무시하기 위한 정규화."""
    text = text.lower()
    text = _PUNCT_RE.sub(" ", text)
    return _WS_RE.sub(" ", text).strip()


def content_fingerprint(item: Item) -> bytes:
    """raw_document.content_hash 에 대응하는 지문."""
    return hashlib.sha256(normalize_text(item.text).encode("utf-8")).digest()


# ---------------------------------------------------------------------------
# 2단계: MinHash + LSH
# ---------------------------------------------------------------------------


def shingles(text: str, k: int = 3) -> frozenset[str]:
    """단어 k-shingle 집합. 짧은 텍스트는 통째로 하나의 shingle."""
    words = normalize_text(text).split()
    if len(words) < k:
        return frozenset({" ".join(words)}) if words else frozenset()
    return frozenset(" ".join(words[i : i + k]) for i in range(len(words) - k + 1))


def _hash_with_seed(value: str, seed: int) -> int:
    digest = hashlib.sha1(f"{seed}:{value}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def minhash_signature(shingle_set: frozenset[str], num_hashes: int = 64) -> tuple[int, ...]:
    if not shingle_set:
        return tuple([0] * num_hashes)
    return tuple(
        min(_hash_with_seed(s, seed) for s in shingle_set) for seed in range(num_hashes)
    )


def jaccard(a: frozenset[str], b: frozenset[str]) -> float:
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def _lsh_bucket_keys(signature: tuple[int, ...], bands: int) -> Iterable[tuple]:
    rows = len(signature) // bands
    for band in range(bands):
        yield (band, signature[band * rows : (band + 1) * rows])


# ---------------------------------------------------------------------------
# 3단계: 의미 기반 (코사인 유사도)
# ---------------------------------------------------------------------------


def _cosine(a: Sequence[float], b: Sequence[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm = math.sqrt(sum(x * x for x in a)) * math.sqrt(sum(y * y for y in b))
    return dot / norm if norm else 0.0


# ---------------------------------------------------------------------------
# 클러스터링 (union-find)
# ---------------------------------------------------------------------------


class _UnionFind:
    def __init__(self) -> None:
        self._parent: dict[int, int] = {}

    def find(self, x: int) -> int:
        self._parent.setdefault(x, x)
        while self._parent[x] != x:
            self._parent[x] = self._parent[self._parent[x]]
            x = self._parent[x]
        return x

    def union(self, a: int, b: int) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self._parent[rb] = ra


# ---------------------------------------------------------------------------
# 파이프라인 본체
# ---------------------------------------------------------------------------


class DedupPipeline:
    def __init__(
        self,
        *,
        minhash_hashes: int = 64,
        lsh_bands: int = 16,
        jaccard_threshold: float = 0.5,
        semantic_threshold: float = 0.85,
        block_window: timedelta = timedelta(hours=48),
        embedder: Optional[Embedder] = None,
    ) -> None:
        if minhash_hashes % lsh_bands != 0:
            raise ValueError("minhash_hashes must be divisible by lsh_bands")
        self.minhash_hashes = minhash_hashes
        self.lsh_bands = lsh_bands
        self.jaccard_threshold = jaccard_threshold
        self.semantic_threshold = semantic_threshold
        self.block_window = block_window
        self.embedder = embedder

    # -- 블로킹: 비교 후보를 (issuer, 시간 윈도) 안으로 제한 --------------------

    def _blocks(self, items: Sequence[Item]) -> Iterable[list[Item]]:
        by_issuer: dict[object, list[Item]] = {}
        for item in items:
            by_issuer.setdefault(item.issuer_id, []).append(item)
        yield from by_issuer.values()

    def _within_window(self, a: Item, b: Item) -> bool:
        if a.published_at is None or b.published_at is None:
            return True
        return abs(a.published_at - b.published_at) <= self.block_window

    # -- 실행 -----------------------------------------------------------------

    def run(self, items: Sequence[Item]) -> list[Cluster]:
        uf = _UnionFind()
        matches: list[Match] = []
        for item in items:
            uf.find(item.id)

        for block in self._blocks(items):
            matches.extend(self._dedup_block(block, uf))

        clusters: dict[int, Cluster] = {}
        for item in items:
            root = uf.find(item.id)
            clusters.setdefault(root, Cluster()).member_ids.append(item.id)
        for match in matches:
            clusters[uf.find(match.item_a)].matches.append(match)
        return list(clusters.values())

    def _dedup_block(self, block: Sequence[Item], uf: _UnionFind) -> list[Match]:
        matches: list[Match] = []
        matched_pairs: set[frozenset[int]] = set()

        def record(a: Item, b: Item, method: str, confidence: float) -> None:
            pair = frozenset((a.id, b.id))
            if pair in matched_pairs:
                return
            matched_pairs.add(pair)
            uf.union(a.id, b.id)
            matches.append(Match(a.id, b.id, method, round(confidence, 3)))

        # 1단계: 완전 일치 (블록 전체를 한 번에)
        by_fingerprint: dict[bytes, Item] = {}
        for item in block:
            fp = content_fingerprint(item)
            first = by_fingerprint.get(fp)
            if first is not None and self._within_window(first, item):
                record(first, item, "exact_hash", 1.0)
            else:
                by_fingerprint.setdefault(fp, item)

        # 2단계: MinHash + LSH 후보 → 자카드 검증
        shingle_sets = {item.id: shingles(item.text) for item in block}
        buckets: dict[tuple, list[Item]] = {}
        for item in block:
            sig = minhash_signature(shingle_sets[item.id], self.minhash_hashes)
            for key in _lsh_bucket_keys(sig, self.lsh_bands):
                buckets.setdefault(key, []).append(item)

        for bucket in buckets.values():
            for i, a in enumerate(bucket):
                for b in bucket[i + 1 :]:
                    if uf.find(a.id) == uf.find(b.id):
                        continue
                    if not self._within_window(a, b):
                        continue
                    similarity = jaccard(shingle_sets[a.id], shingle_sets[b.id])
                    if similarity >= self.jaccard_threshold:
                        record(a, b, "minhash_lsh", similarity)

        # 3단계: 의미 기반 (임베더가 주어진 경우만)
        if self.embedder is not None:
            vectors = {item.id: self.embedder.embed(item.text) for item in block}
            for i, a in enumerate(block):
                for b in block[i + 1 :]:
                    if uf.find(a.id) == uf.find(b.id):
                        continue
                    if not self._within_window(a, b):
                        continue
                    similarity = _cosine(vectors[a.id], vectors[b.id])
                    if similarity >= self.semantic_threshold:
                        record(a, b, "semantic", similarity)

        return matches
