defmodule DisclosureAutomationWeb.TWMOPSMaterialInformationHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.TWMOPSMaterialInformationSource
  alias DisclosureAutomation.Sources

  @event_id "tw.mops.2330.20260430.major_investment_or_asset_sale.material_information_update.1"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(TWMOPSMaterialInformationSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for TW MOPS material information fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/tw_mops_material_information/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/tw") |> json_response(200)
    assert region["slot_id"] == "lane.tw"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    assert item["event_id"] == @event_id
    assert item["event_family"] == "material_information_update"
    assert item["canonical_event_type"] == "major_investment_or_asset_sale"
    assert item["published_at_local"] == "2026-04-30T16:29:38+08:00"
    assert String.starts_with?(item["published_at_utc"], "2026-04-30T08:29:38")
    assert item["filing_date_local"] == "2026-04-30"
    assert item["region_code"] == "tw"
    assert item["home_market_region_code"] == "tw"
    assert get_in(item, ["source_meta", "stable_external_id"]) == "MOPS:2330:20260430:162938:1"
    assert get_in(item, ["source_meta", "cursor_value"]) == "20260430|162938|2330|1"

    event = get(build_conn(), "/api/events/#{@event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == @event_id
    assert get_in(event, ["data", "event_family"]) == "material_information_update"
    assert get_in(event, ["data", "canonical_event_type"]) == "major_investment_or_asset_sale"

    source_health = get(build_conn(), "/api/admin/source-health/tw_mops_material_information") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/tw_mops_material_information/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
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
