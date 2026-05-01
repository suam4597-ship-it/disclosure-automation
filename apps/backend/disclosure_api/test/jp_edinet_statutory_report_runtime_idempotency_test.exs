defmodule DisclosureAutomation.JPEdinetStatutoryReportRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPEdinetStatutoryReportSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
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

  test "EDINET statutory report fixture path closes end-to-end and stays idempotent" do
    assert {:ok, first} = poll_once()
    assert first.records_seen == 1

    assert {:ok, digest1} = Digest.get_latest_digest("breaking")
    assert digest1["item_count"] == 1
    [item1] = digest1["items"]
    assert item1["event_id"] == @event_id
    assert item1["event_family"] == "statutory_report_update"
    assert item1["canonical_event_type"] == "extraordinary_report"
    assert item1["published_at_local"] == "2026-04-30T09:00:00+09:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-04-30T00:00:00")
    assert item1["filing_date_local"] == "2026-04-30"
    assert item1["region_code"] == "jp"
    assert get_in(item1, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item1, ["source_meta", "cursor_key"]) == @cursor_key
    assert get_in(item1, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item1, ["source_meta", "doc_id"]) == "S100XZXO"
    assert get_in(item1, ["source_meta", "edinet_code"]) == "E12460"
    assert get_in(item1, ["source_meta", "doc_type_code"]) == "180"
    assert get_in(item1, ["source_meta", "api_key_redacted"]) == true

    encoded_item = Jason.encode!(item1)
    assert encoded_item =~ "Subscription-Key=<redacted>"
    refute Regex.match?(~r/Subscription-Key=(?!<redacted>)[^\"&\s]+/, encoded_item)

    assert {:ok, second} = poll_once()
    assert second.records_seen == 1

    assert {:ok, digest2} = Digest.get_latest_digest("breaking")
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == @event_id

    source = Repo.get_by!(SourceRegistry, source_key: "jp_edinet_statutory_report")
    assert Repo.aggregate(from(e in RawEvent, where: e.source_registry_id == ^source.id), :count) == 1
    assert Repo.aggregate(from(i in CanonicalFeedItem, where: i.event_id == ^@event_id), :count) == 1
    assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{@stable_external_id}:document-list-row"), :count) == 1
    assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{@stable_external_id}:primary-document:type1"), :count) == 1

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("jp_edinet_statutory_report")
    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == @cursor_key))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
  end

  defp poll_once do
    Ingestion.poll_source("jp_edinet_statutory_report",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end
end
