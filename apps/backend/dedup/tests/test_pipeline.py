"""중복 제거 파이프라인 동작 명세 테스트.

각 테스트는 설계서 4-1장의 약속 하나씩에 대응한다.
실행: python3 -m unittest discover -s apps/backend/dedup -v
"""

import unittest
from datetime import datetime, timedelta, timezone

from pipeline import DedupPipeline, Item

UTC = timezone.utc
T0 = datetime(2026, 6, 10, 2, 0, tzinfo=UTC)


class FakeEmbedder:
    """언어가 달라도 같은 사건이면 같은 벡터를 주는 가짜 임베더 (3단계 테스트용)."""

    def __init__(self, mapping):
        self.mapping = mapping

    def embed(self, text):
        for needle, vector in self.mapping.items():
            if needle in text:
                return vector
        return [1.0, 0.0, 0.0]


def cluster_of(clusters, item_id):
    for cluster in clusters:
        if item_id in cluster.member_ids:
            return cluster
    raise AssertionError(f"item {item_id} not clustered")


class Stage1ExactTest(unittest.TestCase):
    def test_identical_articles_merge_with_full_confidence(self):
        # 통신사 재전송: 구두점/대소문자만 다른 동일 기사
        items = [
            Item(1, "TSMC February Revenue +35.7% YoY", issuer_id=10, published_at=T0),
            Item(2, "tsmc february revenue   +35.7% yoy!!", issuer_id=10, published_at=T0 + timedelta(hours=1)),
        ]
        clusters = DedupPipeline().run(items)
        cluster = cluster_of(clusters, 1)
        self.assertEqual(sorted(cluster.member_ids), [1, 2])
        self.assertEqual(cluster.matches[0].method, "exact_hash")
        self.assertEqual(cluster.matches[0].confidence, 1.0)
        self.assertEqual(cluster.duplicates_removed, 1)


class Stage2NearDuplicateTest(unittest.TestCase):
    def test_lightly_edited_copy_merges_via_minhash(self):
        base = (
            "Broadcom nears 85 billion dollar deal to acquire cloud software giant "
            "VMware in the largest technology acquisition of 2026 signaling continued "
            "consolidation in enterprise software markets worldwide"
        )
        edited = (
            "Broadcom nears 85 billion dollar deal to acquire cloud software giant "
            "VMware in the largest technology acquisition of 2026 signaling further "
            "consolidation across enterprise software markets worldwide"
        )
        items = [
            Item(1, base, issuer_id=20, published_at=T0),
            Item(2, edited, issuer_id=20, published_at=T0 + timedelta(hours=3)),
        ]
        clusters = DedupPipeline().run(items)
        cluster = cluster_of(clusters, 1)
        self.assertEqual(sorted(cluster.member_ids), [1, 2])
        self.assertEqual(cluster.matches[0].method, "minhash_lsh")
        self.assertGreaterEqual(cluster.matches[0].confidence, 0.5)

    def test_unrelated_articles_stay_separate(self):
        items = [
            Item(1, "Toyota raises full year profit forecast on hybrid sales", issuer_id=30, published_at=T0),
            Item(2, "Toyota recalls pickup trucks over brake defect in north america", issuer_id=30, published_at=T0),
        ]
        clusters = DedupPipeline().run(items)
        self.assertEqual(len(clusters), 2)


class Stage3SemanticTest(unittest.TestCase):
    def test_cross_language_reports_merge_with_embedder(self):
        embedder = FakeEmbedder({
            "TSMC monthly revenue": [0.0, 1.0, 0.0],
            "台積電 月次売上": [0.0, 0.99, 0.05],
        })
        items = [
            Item(1, "TSMC monthly revenue hits record on AI demand", issuer_id=10, published_at=T0, language="en"),
            Item(2, "台積電 月次売上が過去最高を記録", issuer_id=10, published_at=T0 + timedelta(hours=2), language="ja"),
        ]
        clusters = DedupPipeline(embedder=embedder).run(items)
        cluster = cluster_of(clusters, 1)
        self.assertEqual(sorted(cluster.member_ids), [1, 2])
        self.assertEqual(cluster.matches[0].method, "semantic")

    def test_without_embedder_cross_language_stays_separate(self):
        items = [
            Item(1, "TSMC monthly revenue hits record on AI demand", issuer_id=10, published_at=T0),
            Item(2, "台積電 月次売上が過去最高を記録", issuer_id=10, published_at=T0),
        ]
        clusters = DedupPipeline().run(items)
        self.assertEqual(len(clusters), 2)


class BlockingTest(unittest.TestCase):
    def test_same_text_different_issuer_is_never_compared(self):
        # 정기 공시 보일러플레이트: 회사가 다르면 같은 문구라도 다른 사건
        text = "monthly revenue report for the period ending"
        items = [
            Item(1, text, issuer_id=10, published_at=T0),
            Item(2, text, issuer_id=20, published_at=T0),
        ]
        clusters = DedupPipeline().run(items)
        self.assertEqual(len(clusters), 2)

    def test_same_text_outside_time_window_stays_separate(self):
        # 매달 반복되는 동일 헤드라인은 별개 사건 (48시간 윈도)
        text = "TSMC monthly revenue report announced"
        items = [
            Item(1, text, issuer_id=10, published_at=T0),
            Item(2, text, issuer_id=10, published_at=T0 + timedelta(days=30)),
        ]
        clusters = DedupPipeline().run(items)
        self.assertEqual(len(clusters), 2)


class DerivedCountTest(unittest.TestCase):
    def test_dedup_banner_count_is_derived(self):
        # 화면의 "중복 N건 제거"는 Σ(클러스터 크기 - 1)
        text = "ASML reports record backlog as EUV demand exceeds capacity"
        items = [
            Item(1, text, issuer_id=40, published_at=T0),
            Item(2, text, issuer_id=40, published_at=T0 + timedelta(hours=1)),
            Item(3, text, issuer_id=40, published_at=T0 + timedelta(hours=2)),
            Item(4, "Santander announces dividend increase", issuer_id=50, published_at=T0),
        ]
        clusters = DedupPipeline().run(items)
        total_removed = sum(c.duplicates_removed for c in clusters)
        self.assertEqual(total_removed, 2)


if __name__ == "__main__":
    unittest.main()
