defmodule DisclosureAutomationWeb.JPTDnetTimelyDisclosureHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Sources

  @event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @cursor_key "latest_disclosure_datetime_security_code_and_pdf_token_seen"
  @cursor_value "2026-04-30T19:00:00+09:00|4527|140120260430515474"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for TDnet fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_tdnet_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/jp") |> json_response(200)
    assert region["slot_id"] == "lane.jp"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    assert item["event_id"] == @event_id
    assert item["event_family"] == "material_information_update"
    assert item["canonical_event_type"] == "material_information_update"
    assert item["published_at_local"] == "2026-04-30T19:00:00+09:00"
    assert String.starts_with?(item["published_at_utc"], "2026-04-30T10:00:00")
    assert item["filing_date_local"] == "2026-04-30"
    assert item["region_code"] == "jp"
    assert item["home_market_region_code"] == "jp"
    assert get_in(item, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item, ["source_meta", "cursor_key"]) == @cursor_key
    assert get_in(item, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item, ["source_meta", "tdnet_raw_row_code"]) == "45270"
    assert get_in(item, ["source_meta", "normalized_security_code"]) == "4527"
    assert get_in(item, ["source_meta", "source_category"]) == nil
    assert get_in(item, ["source_meta", "material_category"]) == "unknown"
    assert get_in(item, ["source_meta", "source_category_inferred"]) == false

    event = get(build_conn(), "/api/events/#{@event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == @event_id
    assert get_in(event, ["data", "event_family"]) == "material_information_update"
    assert get_in(event, ["data", "canonical_event_type"]) == "material_information_update"

    source_health = get(build_conn(), "/api/admin/source-health/jp_tdnet_timely_disclosure") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_tdnet_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    second_poll_payload = json_response(conn, 202)
    assert second_poll_payload["records_seen"] == 1

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == @event_id
    assert hd(digest2["items"])["event_family"] == item["event_family"]
    assert hd(digest2["items"])["canonical_event_type"] == item["canonical_event_type"]
  end
end
