defmodule DisclosureAutomation.Stage57OperatorViewProjectionContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage57OperatorViewProjectionContract

  @valid_attrs %{
    "source_key" => "stage54_offline_provider_fixture",
    "display_name" => "Stage 5.4 Offline Provider Fixture",
    "provider" => "OfflineProvider",
    "source_type" => "api",
    "active" => true,
    "health_status" => "healthy",
    "last_success_at" => "2026-05-02T00:00:00Z",
    "last_failure_at" => nil,
    "last_seen_published_at" => "2026-04-30T10:55:00Z",
    "error_class" => nil,
    "redaction_status" => "passed",
    "manual_review_reason" => nil,
    "request_id_hash" => "sha256:operator-view",
    "cursor_keys" => ["latest_offline_provider_article_seen"],
    "has_recent_safe_overlay" => true,
    "has_visible_overlays" => false,
    "ignored_internal_note" => "drop-me"
  }

  test "defaults are operator-only, read-only, advisory-only, and no-side-effect" do
    assert Stage57OperatorViewProjectionContract.defaults() == %{
             view_scope: "operator_only",
             read_only: true,
             advisory_only: true,
             public_response_shape_mutation: false,
             trigger_live_fetch: false,
             scheduler_enabled: false,
             source_health_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false
           }
  end

  test "projects only allowed redacted fields" do
    assert {:ok, result} = Stage57OperatorViewProjectionContract.project(@valid_attrs)

    assert result.view_scope == "operator_only"
    assert result.read_only == true
    assert result.advisory_only == true
    assert result.public_response_shape_mutation == false
    assert result.trigger_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.source_health_mutation == false
    assert result.canonical_feed_mutation == false
    assert result.provider_canonical_feed_item_creation == false
    assert result.news_only_event_creation == false
    assert result.health_status == "healthy"

    assert result.fields == %{
             source_key: "stage54_offline_provider_fixture",
             display_name: "Stage 5.4 Offline Provider Fixture",
             provider: "OfflineProvider",
             source_type: "api",
             active: true,
             health_status: "healthy",
             last_success_at: "2026-05-02T00:00:00Z",
             last_failure_at: nil,
             last_seen_published_at: "2026-04-30T10:55:00Z",
             error_class: nil,
             redaction_status: "passed",
             manual_review_reason: nil,
             request_id_hash: "sha256:operator-view",
             cursor_keys: ["latest_offline_provider_article_seen"],
             has_recent_safe_overlay: true,
             has_visible_overlays: false
           }

    refute Map.has_key?(result.fields, :ignored_internal_note)
  end

  test "accepts all allowed health states" do
    for status <- Stage57OperatorViewProjectionContract.allowed_health_states() do
      assert {:ok, result} = Stage57OperatorViewProjectionContract.project(%{@valid_attrs | "health_status" => status})
      assert result.health_status == status
      assert result.fields.health_status == status
    end
  end

  test "rejects unknown health states" do
    assert Stage57OperatorViewProjectionContract.project(%{@valid_attrs | "health_status" => "live_fetch_enabled"}) ==
             {:error, {:invalid_operator_view_health_status, "live_fetch_enabled"}}
  end

  test "rejects credentials, request headers, response headers, and full article text" do
    assert Stage57OperatorViewProjectionContract.project(
             Map.put(@valid_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage57OperatorViewProjectionContract.project(
             Map.put(@valid_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ) == {:error, {:prohibited_field, "requestHeaders"}}

    assert Stage57OperatorViewProjectionContract.project(
             Map.put(@valid_attrs, "responseHeaders", %{sensitive_header_name(:cookie) => "not-allowed"})
           ) == {:error, {:prohibited_field, "responseHeaders"}}

    assert Stage57OperatorViewProjectionContract.project(Map.put(@valid_attrs, "fullArticleText", "not allowed")) ==
             {:error, {:prohibited_field, "fullArticleText"}}
  end

  test "rejects raw provider response body and secret-like values" do
    assert Stage57OperatorViewProjectionContract.project(Map.put(@valid_attrs, "rawResponseBody", "not allowed")) ==
             {:error, {:prohibited_field, "rawResponseBody"}}

    assert Stage57OperatorViewProjectionContract.project(
             Map.put(@valid_attrs, "manual_review_reason", sensitive_header_prefix(:authorization) <> " Bearer not-allowed")
           ) == {:error, {:prohibited_field, "manual_review_reason"}}
  end

  test "rejects public exposure, live fetch, and scheduler opt-in" do
    assert Stage57OperatorViewProjectionContract.project(@valid_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage57_operator_view}

    assert Stage57OperatorViewProjectionContract.project(@valid_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage57_operator_view}

    assert Stage57OperatorViewProjectionContract.project(@valid_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage57_operator_view}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
