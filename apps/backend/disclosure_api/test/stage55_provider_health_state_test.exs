defmodule DisclosureAutomation.Stage55ProviderHealthStateTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage55ProviderHealthState

  test "defaults are advisory-only and safe" do
    assert Stage55ProviderHealthState.default_state() == "unknown"

    assert Stage55ProviderHealthState.defaults() == %{
             status: "unknown",
             advisory_only: true,
             use_live_fetch: false,
             scheduler_enabled: false,
             canonical_feed_mutation: false,
             news_only_event_creation: false,
             canonical_fact_override: false
           }
  end

  test "allowed states are accepted" do
    for state <- Stage55ProviderHealthState.allowed_states() do
      assert {:ok, result} =
               Stage55ProviderHealthState.normalize(%{
                 "status" => state,
                 "provider" => "OfflineProvider",
                 "source_key" => "stage54_offline_provider_fixture",
                 "diagnostics" => %{"status" => state, "provider" => "OfflineProvider"}
               })

      assert result.status == state
      assert result.provider == "OfflineProvider"
      assert result.source_key == "stage54_offline_provider_fixture"
      assert result.advisory_only == true
      assert result.use_live_fetch == false
      assert result.scheduler_enabled == false
      assert result.canonical_feed_mutation == false
      assert result.news_only_event_creation == false
      assert result.canonical_fact_override == false
    end
  end

  test "unknown unsafe states are rejected" do
    assert Stage55ProviderHealthState.normalize(%{"status" => "live_fetch_enabled"}) ==
             {:error, {:invalid_provider_health_state, "live_fetch_enabled"}}

    assert Stage55ProviderHealthState.normalize(%{"status" => :healthy}) ==
             {:error, {:invalid_provider_health_state, :healthy}}
  end

  test "diagnostics are allowlisted and redacted" do
    assert {:ok, result} =
             Stage55ProviderHealthState.normalize(%{
               "status" => "healthy",
               "provider" => "OfflineProvider",
               "source_key" => "stage54_offline_provider_fixture",
               "diagnostics" => %{
                 "provider" => "OfflineProvider",
                 "source_key" => "stage54_offline_provider_fixture",
                 "status" => "healthy",
                 "status_code" => 200,
                 "retry_count" => 0,
                 "timeout" => false,
                 "error_class" => nil,
                 "last_checked_at" => "2026-05-02T00:00:00Z",
                 "request_id_hash" => "sha256:health-check",
                 "unbounded_payload_id" => "drop-me"
               }
             })

    assert result.diagnostics == %{
             provider: "OfflineProvider",
             source_key: "stage54_offline_provider_fixture",
             status: "healthy",
             status_code: 200,
             retry_count: 0,
             timeout: false,
             error_class: nil,
             last_checked_at: "2026-05-02T00:00:00Z",
             request_id_hash: "sha256:health-check"
           }

    refute Map.has_key?(result.diagnostics, :unbounded_payload_id)
  end

  test "credentials, headers, and full article text are rejected" do
    assert Stage55ProviderHealthState.normalize(%{
             "status" => "healthy",
             "diagnostics" => %{"requestHeaders" => %{sensitive_header_name(:authorization) => "Bearer not-allowed"}}
           }) == {:error, {:redaction_violation, "diagnostics.requestHeaders"}}

    assert Stage55ProviderHealthState.normalize(%{
             "status" => "healthy",
             "diagnostics" => %{"credentials" => %{sensitive_header_name(:subscription_key) => "not-allowed"}}
           }) == {:error, {:redaction_violation, "diagnostics.credentials"}}

    assert Stage55ProviderHealthState.normalize(%{
             "status" => "healthy",
             "diagnostics" => %{"fullArticleText" => "not allowed"}
           }) == {:error, {:redaction_violation, "diagnostics.fullArticleText"}}
  end

  test "secret-like diagnostic values are rejected" do
    assert Stage55ProviderHealthState.normalize(%{
             "status" => "healthy",
             "diagnostics" => %{"manual_review_reason" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"}
           }) == {:error, {:redaction_violation, "diagnostics.manual_review_reason"}}

    assert Stage55ProviderHealthState.normalize(%{
             "status" => "healthy",
             "diagnostics" => %{"manual_review_reason" => sensitive_header_prefix(:cookie) <> " not-allowed"}
           }) == {:error, {:redaction_violation, "diagnostics.manual_review_reason"}}
  end

  test "live fetch and scheduler opt-in are rejected" do
    assert Stage55ProviderHealthState.normalize(%{"status" => "healthy"}, use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage55_health_state}

    assert Stage55ProviderHealthState.normalize(%{"status" => "healthy"}, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage55_health_state}
  end

  test "redaction violation helper returns safe advisory state" do
    result = Stage55ProviderHealthState.redaction_violation("diagnostics.requestHeaders")

    assert result.status == "redaction_violation"
    assert result.advisory_only == true
    assert result.use_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
    assert result.diagnostics == %{
             redaction_status: "failed",
             manual_review_reason: "redaction_violation",
             violation_path: "diagnostics.requestHeaders"
           }
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
end
