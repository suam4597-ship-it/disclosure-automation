defmodule DisclosureAutomation.SourceHealthMonitoringContractTest do
  use ExUnit.Case, async: true

  @approved_metric_names [
    "source_health.sources.total",
    "source_health.sources.active_total",
    "source_health.sources.inactive_total",
    "source_health.sources.by_status",
    "source_health.sources.by_type",
    "source_health.sources.by_region",
    "source_health.last_success_age_seconds",
    "source_health.last_failure_age_seconds",
    "source_health.sources.stale_total",
    "source_health.sources.never_success_total",
    "source_health.sources.recent_failure_total",
    "source_health.recheck.requests.total",
    "source_health.recheck.responses.total",
    "source_health.recheck.accepted.total",
    "source_health.recheck.forbidden.total",
    "source_health.recheck.not_found.total",
    "source_health.recheck.errors.total",
    "source_health.recheck.idempotency.total",
    "source_health.recheck.idempotency.accepted_total",
    "source_health.recheck.idempotency.reused_total",
    "source_health.recheck.idempotency.untracked_total",
    "source_health.recheck.idempotency.reuse_ratio",
    "source_health.recheck.audit.events.total",
    "source_health.recheck.audit.accepted.total",
    "source_health.recheck.audit.reused.total",
    "source_health.recheck.audit.untracked.total",
    "source_health.recheck.audit.forbidden.total",
    "source_health.recheck.audit.not_found.total",
    "source_health.operator_smoke.last_result",
    "source_health.operator_smoke.last_success_at",
    "source_health.operator_smoke.failure_total",
    "source_health.ui_regression.last_result",
    "source_health.ui_regression.last_success_at",
    "source_health.ui_regression.failure_total"
  ]

  @approved_metric_labels [
    "active",
    "freshness_bucket",
    "health_status",
    "http_status",
    "idempotency_status",
    "redaction_status",
    "region_code",
    "result",
    "result_status",
    "route_operation",
    "source_key",
    "source_type",
    "test_group"
  ]

  @approved_result_statuses [
    "accepted",
    "reused",
    "untracked",
    "forbidden",
    "not_found",
    "error"
  ]

  @approved_idempotency_statuses [
    "accepted",
    "reused",
    "untracked",
    "none"
  ]

  @approved_freshness_buckets [
    "under_15m",
    "15m_to_1h",
    "1h_to_6h",
    "6h_to_24h",
    "over_24h",
    "never"
  ]

  @approved_log_keys [
    "actor_id_hash",
    "event",
    "http_status",
    "idempotency_status",
    "occurred_at",
    "redaction_status",
    "request_id_hash",
    "result_status",
    "route_operation",
    "source_key"
  ]

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

  test "approved source health metric names are bounded to source_health namespace" do
    for metric_name <- @approved_metric_names do
      assert String.starts_with?(metric_name, "source_health.")
      refute String.contains?(metric_name, " ")
      refute String.contains?(metric_name, ":")
      refute_forbidden_fragments(metric_name)
      refute_out_of_scope_fragments(metric_name)
    end
  end

  test "approved metric labels are bounded and do not include raw identifiers" do
    for label <- @approved_metric_labels do
      refute_forbidden_fragments(label)
      refute_out_of_scope_fragments(label)
    end

    assert "source_key" in @approved_metric_labels
    assert "result_status" in @approved_metric_labels
    assert "idempotency_status" in @approved_metric_labels
    assert "redaction_status" in @approved_metric_labels
  end

  test "result, idempotency, and freshness contract values stay allowlisted" do
    assert @approved_result_statuses == [
             "accepted",
             "reused",
             "untracked",
             "forbidden",
             "not_found",
             "error"
           ]

    assert @approved_idempotency_statuses == [
             "accepted",
             "reused",
             "untracked",
             "none"
           ]

    assert @approved_freshness_buckets == [
             "under_15m",
             "15m_to_1h",
             "1h_to_6h",
             "6h_to_24h",
             "over_24h",
             "never"
           ]
  end

  test "approved structured log keys are bounded and hashed where actor/request context appears" do
    assert "actor_id_hash" in @approved_log_keys
    assert "request_id_hash" in @approved_log_keys
    refute "raw_actor_id" in @approved_log_keys
    refute "raw_request_id" in @approved_log_keys
    refute "raw_idempotency_key" in @approved_log_keys

    for key <- @approved_log_keys do
      refute_forbidden_fragments(key)
      refute_out_of_scope_fragments(key)
    end
  end

  test "monitoring contract keeps poll, provider, materializer, and canonical controls out of scope" do
    approved_contract =
      @approved_metric_names ++
        @approved_metric_labels ++
        @approved_result_statuses ++
        @approved_idempotency_statuses ++
        @approved_freshness_buckets ++
        @approved_log_keys

    for value <- approved_contract do
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
