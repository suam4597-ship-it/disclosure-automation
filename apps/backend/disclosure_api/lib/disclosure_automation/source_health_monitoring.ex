defmodule DisclosureAutomation.SourceHealthMonitoring do
  @moduledoc false

  @metric_names [
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

  @metric_labels [
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

  @result_statuses [
    "accepted",
    "reused",
    "untracked",
    "forbidden",
    "not_found",
    "error"
  ]

  @idempotency_statuses [
    "accepted",
    "reused",
    "untracked",
    "none"
  ]

  @freshness_buckets [
    "under_15m",
    "15m_to_1h",
    "1h_to_6h",
    "6h_to_24h",
    "over_24h",
    "never"
  ]

  @structured_log_keys [
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

  @snapshot_sections [
    "overview",
    "freshness",
    "recheck_operations",
    "idempotency",
    "audit_outcomes",
    "operator_smoke",
    "ui_regression"
  ]

  def metric_names, do: @metric_names
  def metric_labels, do: @metric_labels
  def result_statuses, do: @result_statuses
  def idempotency_statuses, do: @idempotency_statuses
  def freshness_buckets, do: @freshness_buckets
  def structured_log_keys, do: @structured_log_keys
  def snapshot_sections, do: @snapshot_sections

  def contract do
    %{
      metric_names: metric_names(),
      metric_labels: metric_labels(),
      result_statuses: result_statuses(),
      idempotency_statuses: idempotency_statuses(),
      freshness_buckets: freshness_buckets(),
      structured_log_keys: structured_log_keys()
    }
  end

  def snapshot_contract do
    %{
      sections: snapshot_sections(),
      metrics: metric_names(),
      labels: metric_labels(),
      result_statuses: result_statuses(),
      idempotency_statuses: idempotency_statuses(),
      freshness_buckets: freshness_buckets(),
      structured_log_keys: structured_log_keys(),
      runtime_emission: false,
      dashboards: false,
      alerts: false,
      log_sinks: false,
      poll_route: "out_of_scope"
    }
  end
end
