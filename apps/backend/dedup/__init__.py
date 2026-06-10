"""GlobalPulse 3단계 중복 제거 참조 구현.

설계 근거: docs/blueprint/data_model_blueprint.md 4-1장.
백엔드(Elixir/Rust)로 이식할 때의 동작 기준이며, 의존성 없이 표준 라이브러리만 쓴다.
"""

from .pipeline import (
    DedupPipeline,
    Embedder,
    Item,
    Match,
    content_fingerprint,
    jaccard,
    minhash_signature,
    normalize_text,
    shingles,
)

__all__ = [
    "DedupPipeline",
    "Embedder",
    "Item",
    "Match",
    "content_fingerprint",
    "jaccard",
    "minhash_signature",
    "normalize_text",
    "shingles",
]
