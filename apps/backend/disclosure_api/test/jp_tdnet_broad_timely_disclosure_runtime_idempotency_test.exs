defmodule DisclosureAutomation.JPTDnetBroadTimelyDisclosureRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetBroadTimelyDisclosureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_ids [
    "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    "jp.tdnet.2871.20260430.material_information_update.material_information_update.140120260430515256",
    "jp.tdnet.6088.20260430.material_information_update.material_information_update.140120260430514945"
  ]

  @stable_ids [
    "TDNET:4527:20260430:1900:140120260430515474",
    "TDNET:2871:20260430:1700:140120260430515256",
    "TDNET:6088:20260430:1700:140120260430514945"
  ]

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetBroadTimelyDisclosureSource.attrs())
    :ok
  end

  test "TDnet broad fixture path closes end-to-end and stays idempotent" do
    assert {:ok, first} = poll_once()
    assert first.records_seen == 3

    assert {:ok, digest1} = Digest.get_latest_digest("breaking")
    assert digest1["item_count"] == 3
    event_ids = Enum.map(digest1["items"], & &1["event_id"])
    assert Enum.sort(event_ids) == Enum.sort(@event_ids)

    for item <- digest1["items"] do
      assert item["event_family"] == "material_information_update"
      assert item["canonical_event_type"] == "material_information_update"
      assert item["region_code"] == "jp"
      assert item["home_market_region_code"] == "jp"
      assert get_in(item, ["source_meta", "source_category"]) == nil
      assert get_in(item, ["source_meta", "material_category"]) == "unknown"
      assert get_in(item, ["source_meta", "source_category_inferred"]) == false
      assert get_in(item, ["source_meta", "tdnet_raw_row_code"]) in ["45270", "28710", "60880"]
      assert get_in(item, ["source_meta", "normalized_security_code"]) in ["4527", "2871", "6088"]
    end

    assert {:ok, second} = poll_once()
    assert second.records_seen == 3

    assert {:ok, digest2} = Digest.get_latest_digest("breaking")
    assert digest2["item_count"] == 3
    assert Enum.sort(Enum.map(digest2["items"], & &1["event_id"])) == Enum.sort(@event_ids)

    source = Repo.get_by!(SourceRegistry, source_key: "jp_tdnet_broad_timely_disclosure")
    assert Repo.aggregate(from(e in RawEvent, where: e.source_registry_id == ^source.id), :count) == 3
    assert Repo.aggregate(from(i in CanonicalFeedItem, where: i.event_id in ^@event_ids), :count) == 3

    for stable_id <- @stable_ids do
      assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{stable_id}:discovery-row"), :count) == 1
    end

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("jp_tdnet_broad_timely_disclosure")
    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_disclosure_datetime_security_code_and_pdf_token_seen"))
  end

  defp poll_once do
    Ingestion.poll_source("jp_tdnet_broad_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end
end
