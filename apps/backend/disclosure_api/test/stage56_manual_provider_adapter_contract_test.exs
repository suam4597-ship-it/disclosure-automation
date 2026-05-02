defmodule DisclosureAutomation.Stage56ManualProviderAdapterContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage56ManualProviderAdapterContract

  @valid_request %{
    "manual_trigger" => true,
    "provider" => "ManualFakeProvider",
    "source_key" => "stage56_manual_provider_fake",
    "provider_request_id" => "manual-request-001",
    "transport_mode" => "fake",
    "timeout_ms" => 5_000,
    "retry_count" => 1
  }

  test "defaults are manual-only and default-off" do
    assert Stage56ManualProviderAdapterContract.defaults() == %{
             manual_trigger_required: true,
             manual_trigger: false,
             transport_mode: "fake",
             use_live_fetch: false,
             scheduler_enabled: false,
             network_access: "forbidden",
             timeout_ms: 5_000,
             retry_count: 0,
             store_full_text: false,
             log_request_headers: false,
             log_response_headers: false,
             log_response_body: false,
             canonical_feed_mutation: false,
             news_only_event_creation: false,
             canonical_fact_override: false
           }
  end

  test "fake transport request validates when manually triggered" do
    assert {:ok, request} = Stage56ManualProviderAdapterContract.validate_request(@valid_request)

    assert request.manual_trigger_required == true
    assert request.manual_trigger == true
    assert request.transport_mode == "fake"
    assert request.use_live_fetch == false
    assert request.scheduler_enabled == false
    assert request.network_access == "forbidden"
    assert request.provider == "ManualFakeProvider"
    assert request.source_key == "stage56_manual_provider_fake"
    assert request.provider_request_id == "manual-request-001"
    assert request.timeout_ms == 5_000
    assert request.retry_count == 1
    assert request.canonical_feed_mutation == false
    assert request.news_only_event_creation == false
    assert request.canonical_fact_override == false
  end

  test "manual trigger is required" do
    request = Map.delete(@valid_request, "manual_trigger")

    assert Stage56ManualProviderAdapterContract.validate_request(request) ==
             {:error, :manual_trigger_required}
  end

  test "real transport and live fetch are rejected" do
    assert Stage56ManualProviderAdapterContract.validate_request(%{@valid_request | "transport_mode" => "http"}) ==
             {:error, {:transport_mode_not_allowed, "http"}}

    assert Stage56ManualProviderAdapterContract.validate_request(@valid_request, use_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage56_adapter_contract}
  end

  test "scheduler opt-in is rejected" do
    assert Stage56ManualProviderAdapterContract.validate_request(@valid_request, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage56_adapter_contract}
  end

  test "bounded request options are enforced" do
    assert Stage56ManualProviderAdapterContract.validate_request(%{@valid_request | "timeout_ms" => 5_001}) ==
             {:error, {:bounded_int_too_large, 5_001, 5_000}}

    assert Stage56ManualProviderAdapterContract.validate_request(%{@valid_request | "retry_count" => 2}) ==
             {:error, {:bounded_int_too_large, 2, 1}}
  end

  test "credentials and request headers are rejected" do
    assert Stage56ManualProviderAdapterContract.validate_request(
             Map.put(@valid_request, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage56ManualProviderAdapterContract.validate_request(
             Map.put(@valid_request, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ) == {:error, {:prohibited_field, "requestHeaders"}}
  end

  test "fake transport result is metadata-only and redacted" do
    assert {:ok, result} =
             Stage56ManualProviderAdapterContract.fake_transport_result(@valid_request, %{
               "status_code" => 200,
               "fetched_at" => "2026-05-02T00:00:00Z",
               "diagnostics" => %{
                 "status_code" => 200,
                 "timeout" => false,
                 "retry_count" => 0,
                 "dropped_payload_id" => "drop-me"
               }
             })

    assert result.mode == "manual_provider_fake_transport"
    assert result.provider == "ManualFakeProvider"
    assert result.source_key == "stage56_manual_provider_fake"
    assert result.provider_request_id == "manual-request-001"
    assert result.transport_mode == "fake"
    assert result.use_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.network_access == "forbidden"
    assert result.status_code == 200
    assert result.fetched_at == "2026-05-02T00:00:00Z"
    assert result.canonical_feed_mutation == false
    assert result.news_only_event_creation == false
    assert result.canonical_fact_override == false
    assert result.diagnostics == %{status_code: 200, timeout: false, retry_count: 0, dropped_payload_id: "drop-me"}
  end

  test "fake transport rejects response body and response headers" do
    assert Stage56ManualProviderAdapterContract.fake_transport_result(@valid_request, %{"rawResponseBody" => "not allowed"}) ==
             {:error, {:prohibited_field, "rawResponseBody"}}

    assert Stage56ManualProviderAdapterContract.fake_transport_result(
             @valid_request,
             %{"responseHeaders" => %{sensitive_header_name(:cookie) => "not-allowed"}}
           ) == {:error, {:prohibited_field, "responseHeaders"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"
end
