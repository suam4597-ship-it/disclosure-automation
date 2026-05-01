defmodule DisclosureAutomationWeb.JPEdinetStatutoryReportHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.JPEdinetStatutoryReportSource
  alias DisclosureAutomation.Sources

  @event_id "jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO"
  @stable_external_id "EDINET:S100XZXO"
  @cursor_key "latest_submit_datetime_and_doc_id_seen"
  @cursor_value "2026-04-30T09:00:00+09:00|S100XZXO"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPEdinetStatutoryReportSource.attrs())
    :ok
  end

  test "health, poll, region, digest, event, and source health close for EDINET fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_edinet_statutory_report/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    region = get(build_conn(), "/api/feed/region/jp") |> json_response(200)
    assert region["slot_id"] == "lane.jp"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    assert item["event_id"] == @event_id
    assert item["event_family"] == "statutory_report_update"
    assert item["canonical_event_type"] == "extraordinary_report"
    assert item["published_at_local"] == "2026-04-30T09:00:00+09:00"
    assert String.starts_with?(item["published_at_utc"], "2026-04-30T00:00:00")
    assert item["filing_date_local"] == "2026-04-30"
    assert item["region_code"] == "jp"
    assert get_in(item, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item, ["source_meta", "cursor_key"]) == @cursor_key
    assert get_in(item, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item, ["source_meta", "doc_id"]) == "S100XZXO"
    assert get_in(item, ["source_meta", "edinet_code"]) == "E12460"
    assert get_in(item, ["source_meta", "api_key_redacted"]) == true

    encoded_item = Jason.encode!(item)
    assert encoded_item =~ "Subscription-Key=<redacted>"
    refute Regex.match?(~r/Subscription-Key=(?!<redacted>)[^\"&\s]+/, encoded_item)

    event = get(build_conn(), "/api/events/#{@event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == @event_id
    assert get_in(event, ["data", "event_family"]) == "statutory_report_update"

    source_health = get(build_conn(), "/api/admin/source-health/jp_edinet_statutory_report") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_edinet_statutory_report/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    second_poll_payload = json_response(conn, 202)
    assert second_poll_payload["records_seen"] == 1
  end
end
