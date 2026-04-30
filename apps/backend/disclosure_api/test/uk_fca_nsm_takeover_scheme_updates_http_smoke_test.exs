defmodule DisclosureAutomationWeb.UKFCANSMTakeoverSchemeUpdatesHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.UKFCANSMTakeoverSchemeUpdatesSource
  alias DisclosureAutomation.Sources

  @event_id "uk.fca_nsm.british_land_company_public_limited_company_the.20260420.tender_offer_or_go_private.takeover_or_scheme_update.5c9e4a51_b4c6_4977_86d3_ac8567261289"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(UKFCANSMTakeoverSchemeUpdatesSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for UK FCA NSM takeover/scheme fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/uk_fca_nsm_takeover_scheme_updates/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/uk") |> json_response(200)
    assert region["slot_id"] == "lane.uk"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    assert item["event_id"] == @event_id
    assert item["event_family"] == "takeover_or_scheme_update"
    assert item["canonical_event_type"] == "tender_offer_or_go_private"
    assert item["published_at_local"] == "2026-04-20T06:00:00+01:00"
    assert String.starts_with?(item["published_at_utc"], "2026-04-20T05:00:00")
    assert item["filing_date_local"] == "2026-04-20"
    assert item["region_code"] == "uk"
    assert item["home_market_region_code"] == "uk"

    event = get(build_conn(), "/api/events/#{@event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == @event_id
    assert get_in(event, ["data", "event_family"]) == "takeover_or_scheme_update"
    assert get_in(event, ["data", "canonical_event_type"]) == "tender_offer_or_go_private"

    source_health = get(build_conn(), "/api/admin/source-health/uk_fca_nsm_takeover_scheme_updates") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/uk_fca_nsm_takeover_scheme_updates/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    _second_poll_payload = json_response(conn, 202)

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == @event_id
    assert hd(digest2["items"])["event_family"] == item["event_family"]
    assert hd(digest2["items"])["canonical_event_type"] == item["canonical_event_type"]
  end
end
