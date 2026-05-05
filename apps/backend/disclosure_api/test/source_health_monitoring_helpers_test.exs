defmodule DisclosureAutomation.SourceHealthMonitoringHelpersTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.SourceHealthMonitoring

  @forbidden_fragments [
    "raw_actor_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason",
    "headers",
    "cookies",
    "tokens",
    "provider_credentials",
    "raw_provider_payload",
    "full_article_text",
    "raw_transport_response",
    "sql_details",
    "stack_trace",
    "canonical_payload",
    "private_actor_context",
    "unbounded_diagnostics",
    "audit_event_id"
  ]

  @out_of_scope_fragments [
    "poll_source",
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch"
  ]

  test "monitoring helper exposes the bounded metric contract" do
    assert SourceHealthMonitoring.contract() == %{
             metric_names: SourceHealthMonitoring.metric_names(),
             metric_labels: SourceHealthMonitoring.metric_labels(),
             result_statuses: SourceHealthMonitoring.result_statuses(),
             idempotency_statuses: SourceHealthMonitoring.idempotency_statuses(),
             freshness_buckets: SourceHealthMonitoring.freshness_buckets(),
             structured_log_keys: SourceHealthMonitoring.structured_log_keys()
           }
  end

  test "monitoring helper metric names stay source_health scoped" do
    for metric_name <- SourceHealthMonitoring.metric_names() do
      assert String.starts_with?(metric_name, "source_health.")
      refute String.contains?(metric_name, " ")
      refute String.contains?(metric_name, ":")
      refute_forbidden_fragments(metric_name)
      refute_out_of_scope_fragments(metric_name)
    end
  end

  test "monitoring helper labels and log keys stay bounded" do
    values = SourceHealthMonitoring.metric_labels() ++ SourceHealthMonitoring.structured_log_keys()

    assert "source_key" in SourceHealthMonitoring.metric_labels()
    assert "result_status" in SourceHealthMonitoring.metric_labels()
    assert "idempotency_status" in SourceHealthMonitoring.metric_labels()
    assert "actor_id_hash" in SourceHealthMonitoring.structured_log_keys()
    assert "request_id_hash" in SourceHealthMonitoring.structured_log_keys()

    refute "raw_actor_id" in SourceHealthMonitoring.structured_log_keys()
    refute "raw_request_id" in SourceHealthMonitoring.structured_log_keys()
    refute "raw_idempotency_key" in SourceHealthMonitoring.structured_log_keys()

    for value <- values do
      refute_forbidden_fragments(value)
      refute_out_of_scope_fragments(value)
    end
  end

  test "monitoring helper statuses stay allowlisted" do
    assert SourceHealthMonitoring.result_statuses() == [
             "accepted",
             "reused",
             "untracked",
             "forbidden",
             "not_found",
             "error"
           ]

    assert SourceHealthMonitoring.idempotency_statuses() == [
             "accepted",
             "reused",
             "untracked",
             "none"
           ]

    assert SourceHealthMonitoring.freshness_buckets() == [
             "under_15m",
             "15m_to_1h",
             "1h_to_6h",
             "6h_to_24h",
             "over_24h",
             "never"
           ]
  end

  test "monitoring helper does not introduce poll, provider, materializer, or canonical controls" do
    contract_values =
      SourceHealthMonitoring.metric_names() ++
        SourceHealthMonitoring.metric_labels() ++
        SourceHealthMonitoring.result_statuses() ++
        SourceHealthMonitoring.idempotency_statuses() ++
        SourceHealthMonitoring.freshness_buckets() ++
        SourceHealthMonitoring.structured_log_keys()

    for value <- contract_values do
      refute_out_of_scope_fragments(value)
    end
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end

  defp refute_out_of_scope_fragments(value) do
    for out_of_scope <- @out_of_scope_fragments do
      refute String.contains?(value, out_of_scope),
             "expected #{inspect(value)} not to include out-of-scope fragment #{inspect(out_of_scope)}"
    end
  end
end
