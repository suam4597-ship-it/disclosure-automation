defmodule DisclosureAutomation.SourceHealthMonitoringSnapshotTest do
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

  test "snapshot contract exposes only bounded monitoring sections" do
    snapshot = SourceHealthMonitoring.snapshot_contract()

    assert snapshot.sections == [
             "overview",
             "freshness",
             "recheck_operations",
             "idempotency",
             "audit_outcomes",
             "operator_smoke",
             "ui_regression"
           ]

    for section <- snapshot.sections do
      refute_forbidden_fragments(section)
      refute_out_of_scope_fragments(section)
    end
  end

  test "snapshot contract reuses helper allowlists without runtime side effects" do
    snapshot = SourceHealthMonitoring.snapshot_contract()

    assert snapshot.metrics == SourceHealthMonitoring.metric_names()
    assert snapshot.labels == SourceHealthMonitoring.metric_labels()
    assert snapshot.result_statuses == SourceHealthMonitoring.result_statuses()
    assert snapshot.idempotency_statuses == SourceHealthMonitoring.idempotency_statuses()
    assert snapshot.freshness_buckets == SourceHealthMonitoring.freshness_buckets()
    assert snapshot.structured_log_keys == SourceHealthMonitoring.structured_log_keys()

    assert snapshot.runtime_emission == false
    assert snapshot.dashboards == false
    assert snapshot.alerts == false
    assert snapshot.log_sinks == false
    assert snapshot.poll_route == "out_of_scope"
  end

  test "snapshot contract values exclude raw private canonical and audit identifiers" do
    snapshot = SourceHealthMonitoring.snapshot_contract()

    values =
      snapshot.sections ++
        snapshot.metrics ++
        snapshot.labels ++
        snapshot.result_statuses ++
        snapshot.idempotency_statuses ++
        snapshot.freshness_buckets ++
        snapshot.structured_log_keys ++
        [to_string(snapshot.poll_route)]

    for value <- values do
      refute_forbidden_fragments(value)
    end
  end

  test "snapshot contract keeps poll provider materializer and canonical controls out of scope" do
    snapshot = SourceHealthMonitoring.snapshot_contract()

    values =
      snapshot.sections ++
        snapshot.metrics ++
        snapshot.labels ++
        snapshot.result_statuses ++
        snapshot.idempotency_statuses ++
        snapshot.freshness_buckets ++
        snapshot.structured_log_keys ++
        [to_string(snapshot.poll_route)]

    for value <- values do
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
