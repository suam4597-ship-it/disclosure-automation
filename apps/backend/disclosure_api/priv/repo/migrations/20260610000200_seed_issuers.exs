defmodule DisclosureAutomation.Repo.Migrations.SeedIssuers do
  use Ecto.Migration

  # Issuer registry seed covering every source region.
  # LEIs verified against public GLEIF records; Broadcom's LEI is
  # intentionally NULL as an unverified example. Mirrors
  # apps/backend/schema/0002_issuer_seed.sql (the design draft).

  @issuers [
    {"Taiwan Semiconductor Manufacturing Company Limited", "549300KB6NK5SBD14S87",
     [
       {"ticker", "2330", "TWSE", nil},
       {"ticker", "TSM", "NYSE", nil},
       {"isin", "TW0002330008", nil, nil},
       {"isin", "US8740391003", nil, nil},
       {"alias", "TSMC", nil, "en"},
       {"alias", "台積電", nil, "zh-Hant"}
     ]},
    {"Tencent Holdings Limited", "254900N4SLUMW4XUYY11",
     [
       {"ticker", "0700", "HKEX", nil},
       {"isin", "KYG875721634", nil, nil},
       {"alias", "騰訊控股", nil, "zh-Hant"}
     ]},
    {"Toyota Motor Corporation", "5493006W3QUS5LMH6R84",
     [
       {"ticker", "7203", "TSE", nil},
       {"ticker", "TM", "NYSE", nil},
       {"isin", "JP3633400001", nil, nil},
       {"alias", "トヨタ自動車", nil, "ja"}
     ]},
    {"Reliance Industries Limited", "5493003UOETFYRONLG31",
     [
       {"ticker", "RELIANCE", "NSE", nil},
       {"isin", "INE002A01018", nil, nil}
     ]},
    {"Samsung Electronics Co., Ltd.", "9884007ER46L6N7EI764",
     [
       {"ticker", "005930", "KRX", nil},
       {"isin", "KR7005930003", nil, nil},
       {"alias", "삼성전자", nil, "ko"}
     ]},
    {"Novo Nordisk A/S", "549300DAQ1CVT6CXN342",
     [
       {"ticker", "NOVO-B", "XCSE", nil},
       {"ticker", "NVO", "NYSE", nil},
       {"isin", "DK0062498333", nil, nil}
     ]},
    {"ASML Holding N.V.", "724500Y6DUVHQD6OXN27",
     [
       {"ticker", "ASML", "XAMS", nil},
       {"ticker", "ASML", "NASDAQ", nil},
       {"isin", "NL0010273215", nil, nil}
     ]},
    {"Banco Santander, S.A.", "5493006QMFDDMYWIAM13",
     [
       {"ticker", "SAN", "BME", nil},
       {"isin", "ES0113900J37", nil, nil}
     ]},
    {"EDP - Energias de Portugal, S.A.", "529900CLC3WDMGI9VH80",
     [
       {"ticker", "EDP", "XLIS", nil},
       {"isin", "PTEDP0AM0009", nil, nil}
     ]},
    {"Broadcom Inc.", nil,
     [
       {"ticker", "AVGO", "NASDAQ", nil},
       {"isin", "US11135F1012", nil, nil}
     ]}
  ]

  def up do
    Enum.each(@issuers, fn {name, lei, identifiers} ->
      execute("""
      INSERT INTO issuers (canonical_name, lei, inserted_at, updated_at)
      VALUES (#{sql_string(name)}, #{sql_string(lei)}, now(), now())
      ON CONFLICT DO NOTHING
      """)

      Enum.each(identifiers, fn {kind, value, exchange, language} ->
        execute("""
        INSERT INTO issuer_identifiers
          (issuer_id, kind, value, exchange, language, inserted_at, updated_at)
        SELECT id, #{sql_string(kind)}, #{sql_string(value)},
               #{sql_string(exchange)}, #{sql_string(language)}, now(), now()
        FROM issuers
        WHERE canonical_name = #{sql_string(name)}
        ON CONFLICT DO NOTHING
        """)
      end)
    end)
  end

  def down do
    Enum.each(@issuers, fn {name, _lei, _identifiers} ->
      execute("DELETE FROM issuers WHERE canonical_name = #{sql_string(name)}")
    end)
  end

  defp sql_string(nil), do: "NULL"
  defp sql_string(value), do: "'#{String.replace(value, "'", "''")}'"
end
