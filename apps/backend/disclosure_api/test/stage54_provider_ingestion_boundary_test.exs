defmodule DisclosureAutomation.Stage54ProviderIngestionBoundaryTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage54ProviderIngestionBoundary

  @valid_payload %{
    "provider" => "OfflineProvider",
    "source_key" => "stage54_offline_provider_fixture",
    "source_tier" => "reputable_news_source",
    "document_role" => "news_article",
    "article_external_id" => "OFFLINE-PROVIDER:jp:140120260430515474:article-001",
    "canonical_event_id" => "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    "matched_official_stable_external_id" => "TDNET:4527:20260430:1900:140120260430515474",
    "title" => "Offline provider metadata-only overlay",
    "published_at" => "2026-04-30T10:55:00Z",
    "url" => "https://example.com/offline-provider/article-001",
    "language" => "en",
    "jurisdiction" => "JP",
    "citations" => [
      %{
        "citation_id" => "offline-provider-overlay-1",
        "source_key" => "stage54_offline_provider_fixture",
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
      "request_id_hash" => "sha256:offline-request-id"
    }
  }

  test "defaults keep live provider ingestion disabled and attach-only" do
    assert Stage54ProviderIngestionBoundary.defaults() == %{
             use_live_fetch: false,
             network_access: "forbidden",
             scheduler_enabled: false,
             overlay_mode: "attach_only",
             canonical_feed_mutation: false,
             news_only_event_creation: false,
             canonical_fact_override: false,
             storage_mode: "metadata_only"
           }
  end

  test "normalizes metadata-only provider result with redacted diagnostics" do
    assert {:ok, result} = Stage54ProviderIngestionBoundary.normalize_result(@valid_payload)

    assert result.mode == "stage54_provider_ingestion_boundary"
    assert result.use_live_fetch == false
    assert result.network_access == "forbidden"
    assert result.scheduler_enabled == false
    assert result.storage_mode == "metadata_only"
    assert result.overlay_mode == "attach_only"
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
    assert result.provider == "OfflineProvider"
    assert result.source_key == "stage54_offline_provider_fixture"
    assert result.source_tier == "reputable_news_source"
    assert result.document_role == "news_article"
    assert result.article_external_id == "OFFLINE-PROVIDER:jp:140120260430515474:article-001"
    assert result.canonical_event_id == @valid_payload["canonical_event_id"]
    assert result.citations == @valid_payload["citations"]
    assert result.overlay_claims == @valid_payload["overlay_claims"]
    assert result.diagnostics == %{
             provider: "OfflineProvider",
             status_code: 200,
             retry_count: 0,
             timeout: false,
             error_class: nil,
             fetched_at: "2026-04-30T10:56:00Z",
             request_id_hash: "sha256:offline-request-id"
           }
  end

  test "rejects live fetch opt-in at the boundary" do
    assert Stage54ProviderIngestionBoundary.normalize_result(@valid_payload, use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage54_boundary}
  end

  test "rejects provider request headers" do
    payload = Map.put(@valid_payload, "requestHeaders", %{"Authorization" => "Bearer secret"})

    assert Stage54ProviderIngestionBoundary.normalize_result(payload) ==
             {:error, {:prohibited_field, "requestHeaders"}}
  end

  test "rejects full article body fields" do
    payload = Map.put(@valid_payload, "articleBody", "full article body must not be stored")

    assert Stage54ProviderIngestionBoundary.normalize_result(payload) ==
             {:error, {:prohibited_field, "articleBody"}}
  end

  test "rejects nested credentials and secret-like values" do
    payload =
      put_in(@valid_payload, ["diagnostics", "credentials"], %{
        "Subscription-Key" => "not-allowed"
      })

    assert Stage54ProviderIngestionBoundary.normalize_result(payload) ==
             {:error, {:prohibited_field, "diagnostics.credentials"}}

    payload = Map.put(@valid_payload, "source_note", "Authorization: Bearer not-allowed")

    assert Stage54ProviderIngestionBoundary.normalize_result(payload) ==
             {:error, {:prohibited_field, "source_note"}}
  end

  test "requires metadata identity fields" do
    payload = Map.drop(@valid_payload, ["provider", "source_key", "article_external_id", "canonical_event_id"])

    assert Stage54ProviderIngestionBoundary.normalize_result(payload) ==
             {:error, {:missing_required_fields, ["provider", "source_key", "article_external_id", "canonical_event_id"]}}
  end

  test "drops non-allowlisted diagnostic metadata" do
    payload =
      put_in(@valid_payload, ["diagnostics", "raw_provider_payload_id"], "internal-raw-payload-id")

    assert {:ok, result} = Stage54ProviderIngestionBoundary.normalize_result(payload)
    refute Map.has_key?(result.diagnostics, :raw_provider_payload_id)
  end
end
