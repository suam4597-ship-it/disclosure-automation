defmodule DisclosureAutomation.SourceHealthPollIdempotencyRateLimitContractTest do
  use ExUnit.Case, async: true

  @idempotency_statuses [
    "accepted",
    "reused",
    "missing_key_denied",
    "expired",
    "untracked_denied"
  ]

  @rate_limit_dimensions [
    "source_key",
    "actor_id_hash",
    "global",
    "region_code",
    "source_type"
  ]

  @required_rate_limit_dimensions [
    "source_key",
    "actor_id_hash",
    "global"
  ]

  @rate_limit_statuses [
    "allowed",
    "rate_limited_source",
    "rate_limited_actor",
    "rate_limited_global",
    "rate_limited_region",
    "rate_limited_source_type"
  ]

  @response_categories [
    "accepted",
    "reused",
    "missing_idempotency_key",
    "rate_limited"
  ]

  @storage_columns [
    "source_key",
    "actor_id_hash",
    "request_id_hash",
    "idempotency_key_hash",
    "status",
    "rate_limit_status",
    "expires_at",
    "last_seen_at",
    "metadata",
    "inserted_at",
    "updated_at"
  ]

  @audit_route_operation "source_health:poll"

  @audit_result_statuses [
    "accepted",
    "reused",
    "missing_key_denied",
    "rate_limited",
    "forbidden",
    "not_found",
    "invalid_request",
    "failed"
  ]

  @bounded_request_context [
    "source_key",
    "actor_id_hash",
    "actor_permissions",
    "request_id_hash",
    "idempotency_key_hash",
    "reason_redacted",
    "redaction_status",
    "created_at"
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
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch",
    "canonical_mutation"
  ]

  test "poll idempotency statuses stay bounded and deny untracked acceptance" do
    assert @idempotency_statuses == [
             "accepted",
             "reused",
             "missing_key_denied",
             "expired",
             "untracked_denied"
           ]

    refute "untracked" in @idempotency_statuses
    refute "untracked_accepted" in @idempotency_statuses

    for status <- @idempotency_statuses do
      refute_forbidden_fragments(status)
      refute_out_of_scope_fragments(status)
    end
  end

  test "poll rate-limit dimensions and statuses stay allowlisted" do
    assert @required_rate_limit_dimensions == ["source_key", "actor_id_hash", "global"]

    for dimension <- @required_rate_limit_dimensions do
      assert dimension in @rate_limit_dimensions
    end

    assert @rate_limit_statuses == [
             "allowed",
             "rate_limited_source",
             "rate_limited_actor",
             "rate_limited_global",
             "rate_limited_region",
             "rate_limited_source_type"
           ]

    for value <- @rate_limit_dimensions ++ @rate_limit_statuses do
      refute_forbidden_fragments(value)
      refute_out_of_scope_fragments(value)
    end
  end

  test "poll bounded request context and storage columns do not include raw private canonical fields" do
    assert "idempotency_key_hash" in @bounded_request_context
    assert "idempotency_key_hash" in @storage_columns
    assert "actor_id_hash" in @storage_columns
    assert "request_id_hash" in @storage_columns
    assert "rate_limit_status" in @storage_columns

    refute "raw_idempotency_key" in @bounded_request_context
    refute "raw_idempotency_key" in @storage_columns
    refute "raw_actor_id" in @storage_columns
    refute "raw_request_id" in @storage_columns

    for value <- @bounded_request_context ++ @storage_columns do
      refute_forbidden_fragments(value)
      refute_out_of_scope_fragments(value)
    end
  end

  test "poll response categories stay bounded" do
    assert @response_categories == [
             "accepted",
             "reused",
             "missing_idempotency_key",
             "rate_limited"
           ]

    refute "provider_fetch" in @response_categories
    refute "materialize" in @response_categories
    refute "canonicalize" in @response_categories

    for category <- @response_categories do
      refute_forbidden_fragments(category)
      refute_out_of_scope_fragments(category)
    end
  end

  test "poll audit result statuses stay bounded and use source_health poll route operation" do
    assert @audit_route_operation == "source_health:poll"

    assert @audit_result_statuses == [
             "accepted",
             "reused",
             "missing_key_denied",
             "rate_limited",
             "forbidden",
             "not_found",
             "invalid_request",
             "failed"
           ]

    refute_forbidden_fragments(@audit_route_operation)
    refute_out_of_scope_fragments(@audit_route_operation)

    for status <- @audit_result_statuses do
      refute_forbidden_fragments(status)
      refute_out_of_scope_fragments(status)
    end
  end

  test "poll contract keeps provider materializer and canonical behavior out of scope" do
    contract_values =
      @idempotency_statuses ++
        @rate_limit_dimensions ++
        @rate_limit_statuses ++
        @response_categories ++
        @storage_columns ++
        @audit_result_statuses ++
        @bounded_request_context ++
        [@audit_route_operation]

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
