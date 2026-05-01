defmodule DisclosureAutomationWeb.JPTDnetBroadTimelyDisclosureHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.JPTDnetBroadTimelyDisclosureSource
  alias DisclosureAutomation.Sources

  @event_ids [
    "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    "jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256",
    "jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945"
  ]

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetBroadTimelyDisclosureSource.attrs())
    :ok
  end

  test "health, poll, region, digest, event, and source health close for broad TDnet fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_tdnet_broad_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 3
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    region = get(build_conn(), "/api/feed/region/jp") |> json_response(200)
    assert region["slot_id"] == "lane.jp"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 3

    items = digest["items"]
    assert Enum.sort(Enum.map(items, & &1["event_id"])) == Enum.sort(@event_ids)

    for item <- items do
      assert item["event_family"] == "material_information_update"
      assert item["canonical_event_type"] == "material_information_update"
      assert item["region_code"] == "jp"
      assert item["home_market_region_code"] == "jp"
      assert get_in(item, ["source_meta", "source_category"]) == nil
      assert get_in(item, ["source_meta", "material_category"]) == "unknown"
      assert get_in(item, ["source_meta", "source_category_inferred"]) == false
    end

    event = get(build_conn(), "/api/events/#{hd(@event_ids)}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == hd(@event_ids)
    assert get_in(event, ["data", "event_family"]) == "material_information_update"

    source_health = get(build_conn(), "/api/admin/source-health/jp_tdnet_broad_timely_disclosure") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/jp_tdnet_broad_timely_disclosure/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    second_poll_payload = json_response(conn, 202)
    assert second_poll_payload["records_seen"] == 3

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 3
    assert Enum.sort(Enum.map(digest2["items"], & &1["event_id"])) == Enum.sort(@event_ids)
  end
end
