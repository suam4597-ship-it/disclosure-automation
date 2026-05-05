defmodule DisclosureAutomation.SourceHealthPollAuditRuntimeContractTest do
  use ExUnit.Case, async: true

  @route_operation "source_health:poll"

  @result_statuses [
    "accepted",
    "reused",
    "missing_key_denied",
    "rate_limited",
    "forbidden",
    "not_found",
    "invalid_request",
    "failed"
  ]

  @idempotency_statuses [
    "accepted",
    "reused",
    "missing_key_denied",
    "none"
  ]

  @rate_limit_statuses [
    "allowed",
    "rate_limited_global",
    "rate_limited_source",
    "rate_limited_actor",
    "none"
  ]

  @outcome_mapping %{
    "accepted" => {"accepted", "accepted", "allowed"},
    "reused" => {"reused", "reused", "allowed"},
    "missing_key" => {"missing_key_denied", "missing_key_denied", "none"},
    "rate_limited_global" => {"rate_limited", "none", "rate_limited_global"},
    "rate_limited_source" => {"rate_limited", "none", "rate_limited_source"},
    "rate_limited_actor" => {"rate_limited", "none", "rate_limited_actor"},
    "forbidden" => {"forbidden", "none", "none"},
    "not_found" => {"not_found", "none", "none"},
    "invalid_request" => {"invalid_request", "none", "none"},
    "failed" => {"failed", "none", "none"}
  }

  @audit_storage_columns [
    "id",
    "source_key",
    "route_operation",
    "result_status",
    "idempotency_status",
    "rate_limit_status",
    "actor_id_hash",
    "request_id_hash",
    "idempotency_key_hash",
    "idempotency_key_id",
    "rate_limit_key_id",
    "reason_redacted",
    "redaction_status",
    "occurred_at",
    "metadata",
    "inserted_at",
    "updated_at"
  ]

  @forbidden_storage_columns [
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
    "unbounded_diagnostics"
  ]

  @forbidden_response_fields [
    "audit_event",
    "audit_event_id",
    "audit_primary_key",
    "idempotency_key_id",
    "rate_limit_key_id",
    "raw_actor_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason"
  ]

  @forbidden_override_fields [
    "operation",
    "action_operation",
    "route_operation",
    "action",
    "queue",
    "worker",
    "payload",
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch"
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
    "unbounded_diagnostics"
  ]

  test "poll audit route operation is fixed and bounded" do
    assert @route_operation == "source_health:poll"
    refute_forbidden_fragments(@route_operation)
  end

  test "poll audit result idempotency and rate-limit statuses stay allowlisted" do
    assert @result_statuses == [
             "accepted",
             "reused",
             "missing_key_denied",
             "rate_limited",
             "forbidden",
             "not_found",
             "invalid_request",
             "failed"
           ]

    assert @idempotency_statuses == ["accepted", "reused", "missing_key_denied", "none"]

    assert @rate_limit_statuses == [
             "allowed",
             "rate_limited_global",
             "rate_limited_source",
             "rate_limited_actor",
             "none"
           ]

    for value <- @result_statuses ++ @idempotency_statuses ++ @rate_limit_statuses do
      refute_forbidden_fragments(value)
    end
  end

  test "poll audit outcome mapping is server-derived and bounded" do
    for {_outcome, {result_status, idempotency_status, rate_limit_status}} <- @outcome_mapping do
      assert result_status in @result_statuses
      assert idempotency_status in @idempotency_statuses
      assert rate_limit_status in @rate_limit_statuses

      refute_forbidden_fragments(result_status)
      refute_forbidden_fragments(idempotency_status)
      refute_forbidden_fragments(rate_limit_status)
    end

    assert @outcome_mapping["accepted"] == {"accepted", "accepted", "allowed"}
    assert @outcome_mapping["reused"] == {"reused", "reused", "allowed"}
    assert @outcome_mapping["missing_key"] == {"missing_key_denied", "missing_key_denied", "none"}
    assert @outcome_mapping["rate_limited_global"] == {"rate_limited", "none", "rate_limited_global"}
    assert @outcome_mapping["forbidden"] == {"forbidden", "none", "none"}
    assert @outcome_mapping["not_found"] == {"not_found", "none", "none"}
  end

  test "poll audit storage columns are bounded" do
    for column <- @audit_storage_columns do
      refute_forbidden_fragments(column)
    end

    assert "route_operation" in @audit_storage_columns
    assert "result_status" in @audit_storage_columns
    assert "idempotency_status" in @audit_storage_columns
    assert "rate_limit_status" in @audit_storage_columns
    assert "actor_id_hash" in @audit_storage_columns
    assert "request_id_hash" in @audit_storage_columns
    assert "idempotency_key_hash" in @audit_storage_columns

    for forbidden <- @forbidden_storage_columns do
      refute forbidden in @audit_storage_columns
    end
  end

  test "poll audit ids stay out of HTTP response contract" do
    for field <- @forbidden_response_fields do
      refute field in bounded_response_fields()
    end
  end

  test "poll audit route operation and statuses cannot be request-body overrides" do
    for field <- @forbidden_override_fields do
      assert is_binary(field)
    end

    refute "route_operation" in server_accepted_override_fields()
    refute "result_status" in server_accepted_override_fields()
    refute "idempotency_status" in server_accepted_override_fields()
    refute "rate_limit_status" in server_accepted_override_fields()
  end

  test "poll audit contract does not approve provider materializer or canonical behavior" do
    contract_values =
      [@route_operation] ++
        @result_statuses ++
        @idempotency_statuses ++
        @rate_limit_statuses ++
        @audit_storage_columns ++
        @forbidden_response_fields

    for value <- contract_values do
      refute value =~ "provider_fetch"
      refute value =~ "materialize"
      refute value =~ "canonicalize"
      refute value =~ "inline_feed"
      refute value =~ "use_live_fetch"
      refute value =~ "canonical_mutation"
    end
  end

  defp bounded_response_fields do
    [
      "source_key",
      "poll_status",
      "idempotency_status",
      "rate_limit_status",
      "error",
      "code",
      "message"
    ]
  end

  defp server_accepted_override_fields do
    [
      "actor_id_hash",
      "actor_permissions",
      "request_id_hash",
      "idempotency_key_hash",
      "reason_redacted",
      "redaction_status",
      "created_at"
    ]
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
