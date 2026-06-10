-- Issuer 명함첩 시드 데이터 (설계서 3장).
-- 수집처 지역(americas, asia_pacific, greater_china, korea, eu_north/central/south)을
-- 모두 커버하는 대표 발행사 10곳.
--
-- LEI는 GLEIF 공개 레코드로 검증된 값만 넣는다. 미검증이면 NULL (Broadcom).
-- ISIN/티커는 거래소 공시 기준의 통용 값이며, 운영 투입 전 GLEIF·거래소 마스터와
-- 대조하는 것을 전제로 한 시드다.

BEGIN;

-- Greater China — TSMC (TWSE MOPS, HKEX 인접 소스와 교차 매칭의 대표 사례)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Taiwan Semiconductor Manufacturing Company Limited', '549300KB6NK5SBD14S87');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', '2330', 'TWSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'TSM', 'NYSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'TW0002330008', NULL, NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'US8740391003', NULL, NULL),  -- ADR
    (currval(pg_get_serial_sequence('issuer', 'id')), 'alias', 'TSMC', NULL, 'en'),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'alias', '台積電', NULL, 'zh-Hant');

-- Greater China — Tencent (HKEX)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Tencent Holdings Limited', '254900N4SLUMW4XUYY11');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', '0700', 'HKEX', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'KYG875721634', NULL, NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'alias', '騰訊控股', NULL, 'zh-Hant');

-- Asia-Pacific — Toyota (JPX)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Toyota Motor Corporation', '5493006W3QUS5LMH6R84');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', '7203', 'TSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'TM', 'NYSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'JP3633400001', NULL, NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'alias', 'トヨタ自動車', NULL, 'ja');

-- Asia-Pacific — Reliance (India NSE 소스)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Reliance Industries Limited', '5493003UOETFYRONLG31');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'RELIANCE', 'NSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'INE002A01018', NULL, NULL);

-- Korea — 삼성전자
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Samsung Electronics Co., Ltd.', '9884007ER46L6N7EI764');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', '005930', 'KRX', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'KR7005930003', NULL, NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'alias', '삼성전자', NULL, 'ko');

-- EU North — Novo Nordisk (Denmark DFSA OAM 소스의 대표 발행사)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Novo Nordisk A/S', '549300DAQ1CVT6CXN342');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'NOVO-B', 'XCSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'NVO', 'NYSE', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'DK0062498333', NULL, NULL);

-- EU Central — ASML (Euronext)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('ASML Holding N.V.', '724500Y6DUVHQD6OXN27');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'ASML', 'XAMS', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'ASML', 'NASDAQ', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'NL0010273215', NULL, NULL);

-- EU South — Banco Santander (Spain CNMV 소스)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Banco Santander, S.A.', '5493006QMFDDMYWIAM13');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'SAN', 'BME', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'ES0113900J37', NULL, NULL);

-- EU South — EDP (Portugal CMVM 소스)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('EDP - Energias de Portugal, S.A.', '529900CLC3WDMGI9VH80');
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'EDP', 'XLIS', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'PTEDP0AM0009', NULL, NULL);

-- Americas — Broadcom. LEI는 GLEIF 레코드 미확인으로 NULL (해소 보류 사례 데모 겸용)
INSERT INTO issuer (canonical_name, lei) VALUES
    ('Broadcom Inc.', NULL);
INSERT INTO issuer_identifier (issuer_id, kind, value, exchange, language) VALUES
    (currval(pg_get_serial_sequence('issuer', 'id')), 'ticker', 'AVGO', 'NASDAQ', NULL),
    (currval(pg_get_serial_sequence('issuer', 'id')), 'isin', 'US11135F1012', NULL, NULL);

COMMIT;
