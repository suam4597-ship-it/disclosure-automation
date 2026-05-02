defmodule DisclosureAutomation.Stage55OfflineProviderHealthEvaluatorTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage55OfflineProviderHealthEvaluator

  @base_attrs %{
    "provider" => "OfflineProvider",
    "source_key" => "stage54_offline_provider_fixture",
    "diagnostics" => %{
      "provider" => "OfflineProvider",
      "source_key" => "stage54_offline_provider_fixture",
      "last_checked_at" => "2026-05-02T00:00:00Z",
      "request_id_hash" => "sha256:offline-health"
    }
  }

  test "success diagnostics evaluate to healthy" do
    assert {:ok, result} = evaluate(%{"status_code" => 200})

    assert result.status == "healthy"
    assert result.evaluation_mode == "offline_provider_health_evaluator"
    assert result.advisory_only == true
    assert result.use_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
  end

  test "partial metadata evaluates to degraded" do
    assert {:ok, result} = evaluate(%{"partial_metadata" => true})
    assert result.status == "degraded"

    assert {:ok, result} = evaluate(%{"metadata_quality" => "stale"})
    assert result.status == "degraded"
  end

  test "rate limit diagnostics evaluate to rate_limited" do
    assert {:ok, result} = evaluate(%{"status_code" => 429})
    assert result.status == "rate_limited"

    assert {:ok, result} = evaluate(%{"error_class" => "rate_limited"})
    assert result.status == "rate_limited"
  end

  test "timeout diagnostics evaluate to timeout" do
    assert {:ok, result} = evaluate(%{"timeout" => true})
    assert result.status == "timeout"
  end

  test "error diagnostics evaluate to failed" do
    assert {:ok, result} = evaluate(%{"error_class" => "provider_error"})
    assert result.status == "failed"
  end

  test "unsafe diagnostics evaluate to redaction_violation without exposing secret-bearing value" do
    assert {:ok, result} =
             evaluate(%{
               "credentials" => %{sensitive_header_name(:subscription_key) => "not-allowed"}
             })

    assert result.status == "redaction_violation"
    assert result.evaluation_mode == "offline_provider_health_evaluator"
    assert result.advisory_only == true
    assert result.use_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
    assert result.diagnostics.redaction_status == "failed"
    assert result.diagnostics.manual_review_reason == "redaction_violation"
    assert result.diagnostics.violation_path == "diagnostics.credentials"
  end

  test "ambiguous or missing match evaluates to manual_review_required" do
    assert {:ok, result} = evaluate(%{"match_status" => "ambiguous"})
    assert result.status == "manual_review_required"

    assert {:ok, result} = evaluate(%{"match_status" => "missing"})
    assert result.status == "manual_review_required"
  end

  test "paused source evaluates to paused" do
    assert {:ok, result} = evaluate(%{"paused" => true})
    assert result.status == "paused"
  end

  test "unknown state stays unknown" do
    assert {:ok, result} = Stage55OfflineProviderHealthEvaluator.evaluate(@base_attrs)
    assert result.status == "unknown"
  end

  test "invalid state still fails through health state contract" do
    assert Stage55OfflineProviderHealthEvaluator.evaluate(Map.put(@base_attrs, "status", "live_fetch_enabled")) ==
             {:error, {:invalid_provider_health_state, "live_fetch_enabled"}}
  end

  test "live fetch and scheduler opt-in are rejected" do
    assert Stage55OfflineProviderHealthEvaluator.evaluate(@base_attrs, use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage55_health_state}

    assert Stage55OfflineProviderHealthEvaluator.evaluate(@base_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage55_health_state}
  end

  defp evaluate(extra_diagnostics) do
    attrs = put_in(@base_attrs, ["diagnostics"], Map.merge(@base_attrs["diagnostics"], extra_diagnostics))
    Stage55OfflineProviderHealthEvaluator.evaluate(attrs)
  end

  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"
end
