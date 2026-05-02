defmodule DisclosureAutomation.Stage54OfflineProviderStagingTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage54OfflineProviderRawStaging
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @official_stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @article_external_id "OFFLINE-PROVIDER:jp:jp_tdnet_timely_disclosure:140120260430515474:article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    :ok
  end

  test "stages normalized offline provider metadata idempotently without canonical mutation" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1
    official_before = canonical_contract(@official_event_id)

    assert {:ok, first_stage} = Stage54OfflineProviderRawStaging.stage_once(provider_payload())
    assert first_stage.records_seen == 1
    assert first_stage.source_key == "stage54_offline_provider_fixture"
    assert first_stage.mode == "offline_provider_raw_staging"
    assert first_stage.use_live_fetch == false
    assert first_stage.network_access == "forbidden"
    assert first_stage.scheduler_enabled == false
    assert first_stage.canonical_feed_mutation == false
    assert first_stage.news_only_event_creation == false
    assert first_stage.canonical_fact_override == false
    assert first_stage.article_external_id == @article_external_id
    assert first_stage.overlay_id =~ "news_overlay:#{@official_event_id}:stage54-"
    assert first_stage.raw_document_external_id == "#{@article_external_id}:article-metadata"
    assert first_stage.raw_event_external_id == "#{first_stage.overlay_id}:overlay-candidate"

    assert raw_document_count() == 1
    assert raw_event_count() == 1

    assert {:ok, second_stage} = Stage54OfflineProviderRawStaging.stage_once(provider_payload())
    assert second_stage.overlay_id == first_stage.overlay_id
    assert second_stage.raw_document_external_id == first_stage.raw_document_external_id
    assert second_stage.raw_event_external_id == first_stage.raw_event_external_id
    assert raw_document_count() == 1
    assert raw_event_count() == 1

    raw_document = raw_document_payload(first_stage.raw_document_external_id)
    assert raw_document["mode"] == "offline_provider_raw_staging"
    assert raw_document["source_key"] == "stage54_offline_provider_fixture"
    assert raw_document["article_external_id"] == @article_external_id
    assert raw_document["canonical_event_id"] == @official_event_id
    assert raw_document["canonical_feed_mutation"] == false
    assert raw_document["news_only_event_creation"] == false
    assert raw_document["canonical_fact_override"] == false
    assert raw_document["network_access"] == "forbidden"
    assert raw_document["scheduler_enabled"] == false
    refute Map.has_key?(raw_document, "articleBody")
    refute Map.has_key?(raw_document, "requestHeaders")
    refute Map.has_key?(raw_document, "credentials")

    raw_event = raw_event_payload(first_stage.raw_event_external_id)
    assert raw_event["overlay_id"] == first_stage.overlay_id
    assert raw_event["article_external_id"] == @article_external_id
    assert raw_event["canonical_event_id"] == @official_event_id
    assert raw_event["canonical_feed_mutation"] == false
    assert raw_event["news_only_event_creation"] == false
    assert raw_event["canonical_fact_override"] == false
    assert raw_event["network_access"] == "forbidden"
    assert raw_event["scheduler_enabled"] == false
    assert get_in(raw_event, ["match_evidence", "matchedCanonicalEventId"]) == @official_event_id
    assert get_in(raw_event, ["match_evidence", "matchedOfficialStableExternalId"]) == @official_stable_external_id
    assert get_in(raw_event, ["official_anchor", "officialSourceKey"]) == "jp_tdnet_timely_disclosure"
    assert raw_event["diagnostics"] == %{
             "provider" => "OfflineProvider",
             "status_code" => 200,
             "retry_count" => 0,
             "timeout" => false,
             "error_class" => nil,
             "fetched_at" => "2026-04-30T10:56:00Z",
             "request_id_hash" => "sha256:offline-request-id"
           }

    assert canonical_count(@official_event_id) == 1
    assert canonical_count(first_stage.overlay_id) == 0
    official_after = canonical_contract(@official_event_id)
    assert official_after["headline_local"] == official_before["headline_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["official_source_url"] == official_before["official_source_url"]
  end

  test "rejects unsafe provider payload before raw staging" do
    unsafe_payload = Map.put(provider_payload(), "requestHeaders", %{"Authorization" => "Bearer not-allowed"})

    assert Stage54OfflineProviderRawStaging.stage_once(unsafe_payload) ==
             {:error, {:prohibited_field, "requestHeaders"}}

    assert raw_document_count() == 0
    assert raw_event_count() == 0
  end

  test "rejects live fetch opt-in before raw staging" do
    assert Stage54OfflineProviderRawStaging.stage_once(provider_payload(), use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage54_boundary}

    assert raw_document_count() == 0
    assert raw_event_count() == 0
  end

  defp provider_payload do
    %{
      "provider" => "OfflineProvider",
      "source_key" => "stage54_offline_provider_fixture",
      "source_tier" => "reputable_news_source",
      "document_role" => "news_article",
      "article_external_id" => @article_external_id,
      "canonical_event_id" => @official_event_id,
      "matched_official_stable_external_id" => @official_stable_external_id,
      "title" => "Offline provider metadata-only overlay",
      "published_at" => "2026-04-30T10:55:00Z",
      "url" => "https://example.com/offline-provider/article-001",
      "language" => "en",
      "jurisdiction" => "JP",
      "citations" => [
        %{
          "citation_id" => "offline-provider-overlay-1",
          "source_key" => "stage54_offline_provider_fixture",
          "document_role" => "news_article",
          "is_canonical_source" => false
        }
      ],
      "overlay_claims" => [
        %{
          "claim_id" => "offline-provider-claim-1",
          "claim_type" => "context_summary",
          "canonical_fact_override" => false
        }
      ],
      "diagnostics" => %{
        "provider" => "OfflineProvider",
        "status_code" => 200,
        "retry_count" => 0,
        "timeout" => false,
        "error_class" => nil,
        "fetched_at" => "2026-04-30T10:56:00Z",
        "request_id_hash" => "sha256:offline-request-id",
        "raw_provider_payload_id" => "not-persisted"
      }
    }
  end

  defp poll_tdnet_once do
    Ingestion.poll_source("jp_tdnet_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end

  defp raw_document_count do
    %{rows: [[count]]} =
      Repo.query!(
        """
        select count(*)
        from raw_documents rd
        join source_registry sr on sr.id = rd.source_registry_id
        where sr.source_key = $1
        """,
        ["stage54_offline_provider_fixture"]
      )

    count
  end

  defp raw_event_count do
    %{rows: [[count]]} =
      Repo.query!(
        """
        select count(*)
        from raw_events re
        join source_registry sr on sr.id = re.source_registry_id
        where sr.source_key = $1
        """,
        ["stage54_offline_provider_fixture"]
      )

    count
  end

  defp raw_document_payload(external_id) do
    %{rows: [[payload]]} =
      Repo.query!(
        """
        select payload
        from raw_documents rd
        join source_registry sr on sr.id = rd.source_registry_id
        where sr.source_key = $1 and rd.external_id = $2
        limit 1
        """,
        ["stage54_offline_provider_fixture", external_id]
      )

    payload
  end

  defp raw_event_payload(external_event_key) do
    %{rows: [[payload]]} =
      Repo.query!(
        """
        select payload
        from raw_events re
        join source_registry sr on sr.id = re.source_registry_id
        where sr.source_key = $1 and re.external_event_key = $2
        limit 1
        """,
        ["stage54_offline_provider_fixture", external_event_key]
      )

    payload
  end

  defp canonical_count(event_id) do
    %{rows: [[count]]} = Repo.query!("select count(*) from canonical_feed_items where event_id = $1", [event_id])
    count
  end

  defp canonical_contract(event_id) do
    %{rows: [[contract]]} = Repo.query!("select contract_v1 from canonical_feed_items where event_id = $1", [event_id])
    contract
  end
end
