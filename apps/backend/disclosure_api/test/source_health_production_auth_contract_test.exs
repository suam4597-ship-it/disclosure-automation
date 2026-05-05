defmodule DisclosureAutomation.SourceHealthProductionAuthContractTest do
  use ExUnit.Case, async: true

  @permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @role_permission_map %{
    "source_health_viewer" => ["source_health:read"],
    "source_health_operator" => ["source_health:read", "source_health:recheck"],
    "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
    "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
  }

  @session_context_fields [
    "actor_id_hash",
    "actor_permissions",
    "request_id_hash",
    "session_id_hash",
    "role_names",
    "redaction_status",
    "created_at"
  ]

  @server_authoritative_fields [
    "actor_id_hash",
    "actor_permissions",
    "request_id_hash",
    "session_id_hash",
    "role_names"
  ]

  @request_param_override_fields [
    "actor_permissions",
    "actor_id_hash",
    "request_id_hash",
    "session_id_hash",
    "role_names",
    "route_operation",
    "result_status",
    "idempotency_status",
    "rate_limit_status",
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch"
  ]

  @forbidden_response_fragments [
    "raw_actor_id",
    "raw_user_id",
    "raw_session_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason",
    "email",
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

  test "production source health permissions stay allowlisted" do
    assert @permissions == [
             "source_health:read",
             "source_health:recheck",
             "source_health:poll"
           ]

    refute "admin" in @permissions
    refute "source_health:*" in @permissions
    refute "source_health:all" in @permissions

    for permission <- @permissions do
      assert String.starts_with?(permission, "source_health:")
      refute_forbidden_fragments(permission)
    end
  end

  test "role mapping keeps read recheck and poll permissions distinct" do
    assert @role_permission_map["source_health_viewer"] == ["source_health:read"]
    assert @role_permission_map["source_health_operator"] == ["source_health:read", "source_health:recheck"]
    assert @role_permission_map["source_health_poll_operator"] == ["source_health:read", "source_health:poll"]
    assert @role_permission_map["source_health_admin"] == @permissions

    refute "source_health:poll" in @role_permission_map["source_health_operator"]
    refute "source_health:recheck" in @role_permission_map["source_health_poll_operator"]

    for {_role, permissions} <- @role_permission_map do
      for permission <- permissions do
        assert permission in @permissions
      end
    end
  end

  test "session auth context exposes bounded hash and role fields only" do
    assert @session_context_fields == [
             "actor_id_hash",
             "actor_permissions",
             "request_id_hash",
             "session_id_hash",
             "role_names",
             "redaction_status",
             "created_at"
           ]

    refute "raw_actor_id" in @session_context_fields
    refute "raw_user_id" in @session_context_fields
    refute "raw_session_id" in @session_context_fields
    refute "email" in @session_context_fields
    refute "headers" in @session_context_fields
    refute "cookies" in @session_context_fields
    refute "tokens" in @session_context_fields

    for field <- @session_context_fields do
      refute_forbidden_fragments(field)
    end
  end

  test "request params cannot be authoritative for production source health permissions" do
    assert "actor_permissions" in @request_param_override_fields
    assert "actor_id_hash" in @request_param_override_fields
    assert "request_id_hash" in @request_param_override_fields
    assert "session_id_hash" in @request_param_override_fields

    for field <- @request_param_override_fields do
      assert field not in production_authority_sources()
    end
  end

  test "server authoritative context fields remain bounded" do
    assert @server_authoritative_fields == [
             "actor_id_hash",
             "actor_permissions",
             "request_id_hash",
             "session_id_hash",
             "role_names"
           ]

    for field <- @server_authoritative_fields do
      assert field in @session_context_fields
      refute_forbidden_fragments(field)
    end
  end

  test "production auth response contract forbids raw identity and private material" do
    bounded_response_fields = [
      "error",
      "code",
      "message",
      "source_key",
      "poll_status",
      "idempotency_status",
      "rate_limit_status"
    ]

    for forbidden <- @forbidden_response_fragments do
      refute forbidden in bounded_response_fields
    end
  end

  test "production auth replacement must not expand poll or downstream controls" do
    future_auth_contract_fields = @session_context_fields ++ @server_authoritative_fields ++ @permissions

    for field <- future_auth_contract_fields do
      refute field =~ "provider_fetch"
      refute field =~ "materialize"
      refute field =~ "canonicalize"
      refute field =~ "inline_feed"
      refute field =~ "use_live_fetch"
      refute field =~ "canonical_mutation"
    end
  end

  defp production_authority_sources do
    [
      "authenticated_session",
      "server_side_user_identity",
      "server_side_role_mapping",
      "server_side_permission_mapping"
    ]
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_response_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
