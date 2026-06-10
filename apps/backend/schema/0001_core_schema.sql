-- GlobalPulse core schema draft (PostgreSQL)
-- 설계 근거: docs/blueprint/data_model_blueprint.md
--
-- 백엔드(fly.dev)가 이 스키마로 정렬되기 전까지는 "설계의 단일 기준" 역할을 한다.
-- 모든 timestamptz 컬럼은 UTC 저장이 전제다. 타임존 변환은 표시 계층에서만 한다.

BEGIN;

-- ---------------------------------------------------------------------------
-- 수집처 (config/sources.yml 의 DB 미러)
-- ---------------------------------------------------------------------------
CREATE TABLE source (
    key                 text PRIMARY KEY,           -- 예: hkex_latest_listed_company_information
    name                text NOT NULL,
    region              text NOT NULL,              -- americas | eu_north | greater_china | ...
    timezone            text NOT NULL,              -- IANA 존 이름 (예: Asia/Hong_Kong). 오프셋 금지
    status              text NOT NULL DEFAULT 'disabled'
                        CHECK (status IN ('disabled', 'fixture', 'canary', 'production')),
    records_seen_cap    integer NOT NULL DEFAULT 25,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 회사 명함첩 (Issuer): 회사 1곳 = 1행, 모든 별명/코드는 identifier 로 매달기
-- ---------------------------------------------------------------------------
CREATE TABLE issuer (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    canonical_name  text NOT NULL,
    lei             text UNIQUE,                    -- 국제 표준 법인 식별자. 교차 매칭의 앵커
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE issuer_identifier (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    issuer_id   bigint NOT NULL REFERENCES issuer (id) ON DELETE CASCADE,
    kind        text NOT NULL CHECK (kind IN ('ticker', 'isin', 'alias', 'local_code')),
    value       text NOT NULL,
    exchange    text,                               -- ticker 일 때: TWSE, NYSE, HKEX ...
    language    text,                               -- alias 일 때: en, ja, zh-Hant ...
    UNIQUE (kind, value, exchange)
);

CREATE INDEX issuer_identifier_lookup ON issuer_identifier (value, kind);

-- ---------------------------------------------------------------------------
-- 1층: 원본 (불변). UPDATE/DELETE 금지 — 재처리의 기준점
-- ---------------------------------------------------------------------------
CREATE TABLE raw_document (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_key       text NOT NULL REFERENCES source (key),
    idempotency_key  text NOT NULL,                 -- source_key + 원천 고유ID (또는 content_hash)
    content_hash     bytea NOT NULL,                -- 본문 SHA-256. dedup 1단계(정확 일치)에 사용
    storage_ref      text NOT NULL,                 -- object storage 경로 (본문은 DB 밖에)
    http_status      integer,
    fetch_mode       text NOT NULL CHECK (fetch_mode IN ('live', 'fixture')),
    fetched_at       timestamptz NOT NULL DEFAULT now(),  -- transaction time (UTC)

    UNIQUE (idempotency_key)                        -- 같은 글 재수집 시 삽입 거부 = 멱등성
);

CREATE INDEX raw_document_content_hash ON raw_document (content_hash);
CREATE INDEX raw_document_source_fetched ON raw_document (source_key, fetched_at DESC);

-- ---------------------------------------------------------------------------
-- 2층: 정리된 기사/공시 (1건 = 1행)
-- ---------------------------------------------------------------------------
CREATE TABLE normalized_item (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    raw_document_id  bigint NOT NULL REFERENCES raw_document (id),  -- 계보: 어느 원본에서 왔나
    source_key       text NOT NULL REFERENCES source (key),
    title            text NOT NULL,
    summary          text,
    body_text        text,
    language         text NOT NULL,                 -- en | ja | zh-Hant | ko ...
    issuer_id        bigint REFERENCES issuer (id), -- 미해소(회사 못 찾음) 시 NULL
    url              text,

    -- 이중 시간(bitemporal): "세상의 시간"과 "우리 장부의 시간"을 분리
    published_at_utc timestamptz NOT NULL,          -- valid time: 원천 발행 시각 (UTC)
    source_timezone  text NOT NULL,                 -- 원천의 IANA 존 (표시용 보존)
    ingested_at      timestamptz NOT NULL DEFAULT now(),  -- transaction time

    parser_key       text NOT NULL,
    schema_version   integer NOT NULL DEFAULT 1
);

CREATE INDEX normalized_item_issuer_published
    ON normalized_item (issuer_id, published_at_utc DESC);
CREATE INDEX normalized_item_published ON normalized_item (published_at_utc DESC);

-- ---------------------------------------------------------------------------
-- 3층: 사건 (사건 1개 = 1행) + 증거 (사건 ↔ 기사 N:M)
-- ---------------------------------------------------------------------------
CREATE TABLE canonical_event (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    headline            text NOT NULL,              -- 증거 중 가장 정보가 많은 것에서 채움
    summary             text,
    issuer_id           bigint REFERENCES issuer (id),
    region              text NOT NULL,
    occurred_at_utc     timestamptz NOT NULL,       -- valid time: 사건/최초 발행 시각
    first_seen_at       timestamptz NOT NULL DEFAULT now(),  -- transaction time
    last_updated_at     timestamptz NOT NULL DEFAULT now(),
    -- 대표 기사: evidence 확정 후 채워지므로 nullable, FK는 event_evidence 생성 후 추가
    primary_evidence_id bigint
);

CREATE INDEX canonical_event_region_occurred
    ON canonical_event (region, occurred_at_utc DESC);
CREATE INDEX canonical_event_issuer ON canonical_event (issuer_id, occurred_at_utc DESC);

CREATE TABLE event_evidence (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    canonical_event_id  bigint NOT NULL REFERENCES canonical_event (id) ON DELETE CASCADE,
    normalized_item_id  bigint NOT NULL REFERENCES normalized_item (id),
    -- 어느 체(dedup 단계)에 걸려 합쳐졌는지 — 오병합 추적/복구의 근거
    match_method        text NOT NULL
                        CHECK (match_method IN ('exact_hash', 'minhash_lsh', 'semantic', 'manual')),
    confidence          numeric(4, 3) NOT NULL DEFAULT 1.000
                        CHECK (confidence >= 0 AND confidence <= 1),
    is_primary          boolean NOT NULL DEFAULT false,
    linked_at           timestamptz NOT NULL DEFAULT now(),

    UNIQUE (canonical_event_id, normalized_item_id)
);

-- 한 기사가 두 사건의 증거가 되는 것은 허용하지 않음 (1기사 = 최대 1사건)
CREATE UNIQUE INDEX event_evidence_item_unique ON event_evidence (normalized_item_id);
-- 사건당 대표 기사는 1건
CREATE UNIQUE INDEX event_evidence_one_primary
    ON event_evidence (canonical_event_id) WHERE is_primary;

ALTER TABLE canonical_event
    ADD CONSTRAINT canonical_event_primary_evidence_fk
    FOREIGN KEY (primary_evidence_id) REFERENCES event_evidence (id);

-- 화면의 "중복 N건 제거"는 저장값이 아니라 이 뷰처럼 계산값이다
CREATE VIEW event_dedup_stats AS
SELECT
    canonical_event_id,
    count(*)              AS evidence_count,
    count(*) - 1          AS duplicates_removed
FROM event_evidence
GROUP BY canonical_event_id;

-- ---------------------------------------------------------------------------
-- 카테고리: 복수 태그 + 분류 기준 버전 + 분류 주체 기록
-- ---------------------------------------------------------------------------
CREATE TABLE category (
    key   text PRIMARY KEY,    -- earnings | ma_capital_flow | supply_demand
                               -- | tech_innovation | shortage_surge
    name  text NOT NULL
);

INSERT INTO category (key, name) VALUES
    ('earnings',        'Earnings Reports'),
    ('ma_capital_flow', 'M&A / Capital Flow'),
    ('supply_demand',   'Supply / Demand Changes'),
    ('tech_innovation', 'Tech Innovation'),
    ('shortage_surge',  'Product Shortage / Demand Surge');

CREATE TABLE event_category (
    canonical_event_id bigint NOT NULL REFERENCES canonical_event (id) ON DELETE CASCADE,
    category_key       text NOT NULL REFERENCES category (key),
    taxonomy_version   integer NOT NULL DEFAULT 1,
    classifier         text NOT NULL CHECK (classifier IN ('rule', 'ml', 'human')),
    confidence         numeric(4, 3) NOT NULL DEFAULT 1.000
                       CHECK (confidence >= 0 AND confidence <= 1),

    PRIMARY KEY (canonical_event_id, category_key)
);

-- ---------------------------------------------------------------------------
-- 4층: 전달 패킷 (3층의 읽기 전용 투영)
-- ---------------------------------------------------------------------------
CREATE TABLE digest (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    edition      text NOT NULL,                     -- breaking | daily | ...
    region       text,                              -- NULL 이면 전체
    generated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX digest_latest ON digest (edition, generated_at DESC);

CREATE TABLE digest_item (
    digest_id          bigint NOT NULL REFERENCES digest (id) ON DELETE CASCADE,
    canonical_event_id bigint NOT NULL REFERENCES canonical_event (id),
    rank               integer NOT NULL,

    PRIMARY KEY (digest_id, canonical_event_id),
    UNIQUE (digest_id, rank)
);

COMMIT;
