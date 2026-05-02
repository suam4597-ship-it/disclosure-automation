defmodule DisclosureAutomation.Stage56RedactedProviderResultAdapterTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage56RedactedProviderResultAdapter

  @transport_result %{
    "mode" => "manual_provider_fake_transport",
    "provider" => "ManualFakeProvider",
    "source_key" => "stage56_manual_provider_fake",
    "provider_request_id" => "manual-request-001",
    "transport_mode" => "fake",
    "use_live_fetch" => false,
    "scheduler_enabled" => false,
    "network_access" => "forbidden",
    "status_code" => 200,
    "fetched_at" => "2026-05-02T00:00:00Z",
    "diagnostics" => %{
      "status_code" => 200,
      "retry_count" => 0,
      "timeout" => false,
      "error_class" => nil,
      "request_id_hash" => "sha256:manual-fake-request"
    },
    "canonical_feed_mutation" => false,
    "news_only_event_creation" => false,
    "canonical_fact_override" => false
  }

  @article_attrs %{
    "provider" => "ManualFakeProvider",
    "source_key" => "stage56_manual_provider_fake",
    "source_tier" => "reputable_news_source",
    "document_role" => "news_article",
    "article_external_id" => "MANUAL-FAKE:jp:140120260430515474:article-001",
    "canonical_event_id" => "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    "matched_official_stable_external_id" => "TDNET:4527:20260430:1900:140120260430515474",
    "title" => "Manual fake provider metadata-only overlay",
    "published_at" => "2026-04-30T10:55:00Z",
    "url" => "https://example.com/manual-fake-provider/article-001",
    "language" => "en",
    "jurisdiction" => "JP",
    "citations" => [
      %{
        "citation_id" => "manual-fake-provider-overlay-1",
        "source_key" => "stage56_manual_provider_fake",
        "document_role" => "news_article",
        "is_canonical_source" => false
      }
    ],
    "overlay_claims" => [
      %{
        "claim_id" => "manual-fake-provider-claim-1",
        "claim_type" => "context_summary",
        "canonical_fact_override" => false
      }
    ]
  }

  test "maps fake transport metadata into Stage 5.4 provider ingestion boundary output" do
    assert {:ok, result} = Stage56RedactedProviderResultAdapter.to_boundary_payload(@transport_result, @article_attrs)

    assert result.adapter_mode == "stage56_redacted_provider_result_adapter"
    assert result.mode == "stage54_provider_ingestion_boundary"
    assert result.transport_mode == "fake"
    assert result.provider == "ManualFakeProvider"
    assert result.source_key == "stage56_manual_provider_fake"
    assert result.source_tier == "reputable_news_source"
    assert result.document_role == "news_article"
    assert result.article_external_id == "MANUAL-FAKE:jp:140120260430515474:article-001"
    assert result.canonical_event_id == @article_attrs["canonical_event_id"]
    assert result.matched_official_stable_external_id == @article_attrs["matched_official_stable_external_id"]
    assert result.title == "Manual fake provider metadata-only overlay"
    assert result.published_at == "2026-04-30T10:55:00Z"
    assert result.url == "https://example.com/manual-fake-provider/article-001"
    assert result.language == "en"
    assert result.jurisdiction == "JP"
    assert result.citations == @article_attrs["citations"]
    assert result.overlay_claims == @article_attrs["overlay_claims"]
    assert result.use_live_fetch == false
    assert result.network_access == "forbidden"
    assert result.scheduler_enabled == false
    assert result.storage_mode == "metadata_only"
    assert result.overlay_mode == "attach_only"
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
    assert result.diagnostics == %{
             provider: "ManualFakeProvider",
             status_code: 200,
             retry_count: 0,
             timeout: false,
             error_class: nil,
             fetched_at: "2026-05-02T00:00:00Z",
             request_id_hash: "sha256:manual-fake-request"
           }
  end

  test "rejects non-fake transport mode" do
    transport_result = Map.put(@transport_result, "transport_mode", "http")

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(transport_result, @article_attrs) ==
             {:error, {:transport_mode_not_allowed, "http"}}
  end

  test "rejects live fetch and scheduler opt-in" do
    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(@transport_result, @article_attrs, use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage56_result_adapter}

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(@transport_result, @article_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage56_result_adapter}
  end

  test "rejects raw response body and full article text before boundary normalization" do
    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             Map.put(@transport_result, "rawResponseBody", "not allowed"),
             @article_attrs
           ) == {:error, {:prohibited_field, "rawResponseBody"}}

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             @transport_result,
             Map.put(@article_attrs, "fullArticleText", "not allowed")
           ) == {:error, {:prohibited_field, "fullArticleText"}}
  end

  test "rejects request and response headers" do
    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             Map.put(@transport_result, "responseHeaders", %{sensitive_header_name(:cookie) => "not-allowed"}),
             @article_attrs
           ) == {:error, {:prohibited_field, "responseHeaders"}}

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             @transport_result,
             Map.put(@article_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ) == {:error, {:prohibited_field, "requestHeaders"}}
  end

  test "rejects credentials and secret-like values" do
    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             @transport_result,
             Map.put(@article_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(
             put_in(@transport_result, ["diagnostics", "manual_review_reason"], sensitive_header_prefix(:authorization) <> " Bearer not-allowed"),
             @article_attrs
           ) == {:error, {:prohibited_field, "diagnostics.manual_review_reason"}}
  end

  test "requires Stage 5.4 boundary fields" do
    article_attrs = Map.delete(@article_attrs, "canonical_event_id")

    assert Stage56RedactedProviderResultAdapter.to_boundary_payload(@transport_result, article_attrs) ==
             {:error, {:missing_required_fields, ["canonical_event_id"]}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
