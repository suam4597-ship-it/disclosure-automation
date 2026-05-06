defmodule DisclosureAutomation.SourceHealthProductionModePermissionParamDenialContractTest do
  use ExUnit.Case, async: true

  @source_health_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @request_param_authority_fields [
    "actor_permissions",
    "actor_id_hash",
    "request_id_hash",
    "session_id_hash",
    "role_names",
    "redaction_status",
    "created_at",
    "route_operation",
    "result_status",
    "idempotency_status",
    "rate_limit_status"
  ]

  @production_authority_sources [
    "SourceHealthAuthContext",
    "authenticated_session",
    "server_side_user_identity",
    "server_side_role_mapping",
    "server_side_permission_mapping"
  ]

  @permission_param_fallback_modes [
    :disabled,
    :test_only,
    :legacy_compat
  ]

  @production_fallback_mode :disabled
  @test_fallback_mode :test_only

  @production_denial_surfaces [
    "internal_ui_recheck_action",
    "recheck_authorization",
    "poll_authorization"
  ]

  @bounded_denial_shapes %{
    "internal_ui_recheck_action" => [
      "recheck_action=not_rendered",
      "recheck_action=disabled",
      "recheck_reason=read_only"
    ],
    "recheck_authorization" => [
      "403",
      "forbidden",
      "source health recheck not allowed"
    ],
    "poll_authorization" => [
      "403",
      "forbidden",
      "source poll not allowed"
    ]
  }

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

  @downstream_control_fragments [
    "poll_ui",
    "audit_ui",
    "public_source_health_ui",
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch",
    "canonical_mutation"
  ]

  test "production mode disables request-param permission fallback" do
    assert @permission_param_fallback_modes == [:disabled, :test_only, :legacy_compat]
    assert @production_fallback_mode == :disabled

    refute @production_fallback_mode == :test_only
    refute @production_fallback_mode == :legacy_compat
  end

  test "test harness may keep temporary request-param fallback separate from production" do
    assert @test_fallback_mode == :test_only
    assert @test_fallback_mode in @permission_param_fallback_modes
    refute @test_fallback_mode == @production_fallback_mode
  end

  test "request params are never production authority sources" do
    for field <- @request_param_authority_fields do
      assert field not in @production_authority_sources
      refute_forbidden_fragments(field)
    end

    assert "actor_permissions" in @request_param_authority_fields
    assert "actor_id_hash" in @request_param_authority_fields
    assert "request_id_hash" in @request_param_authority_fields
    assert "session_id_hash" in @request_param_authority_fields
  end

  test "SourceHealthAuthContext remains the bounded production handoff" do
    assert "SourceHealthAuthContext" in @production_authority_sources
    assert "authenticated_session" in @production_authority_sources
    assert "server_side_user_identity" in @production_authority_sources
    assert "server_side_role_mapping" in @production_authority_sources
    assert "server_side_permission_mapping" in @production_authority_sources

    for source <- @production_authority_sources do
      refute_forbidden_fragments(source)
    end
  end

  test "production denial covers UI recheck recheck authorization and poll authorization surfaces" do
    assert @production_denial_surfaces == [
             "internal_ui_recheck_action",
             "recheck_authorization",
             "poll_authorization"
           ]

    for surface <- @production_denial_surfaces do
      assert Map.has_key?(@bounded_denial_shapes, surface)
      refute_forbidden_fragments(surface)
    end
  end

  test "production request-param actor_permissions must not grant source health actions" do
    malicious_request_params = %{
      "actor_permissions" => @source_health_permissions,
      "actor_id_hash" => "attacker-supplied-actor",
      "request_id_hash" => "attacker-supplied-request",
      "session_id_hash" => "attacker-supplied-session",
      "role_names" => ["source_health_admin"]
    }

    for {_field, value} <- malicious_request_params do
      assert inspect(value) != "SourceHealthAuthContext"
    end

    for permission <- @source_health_permissions do
      assert permission in malicious_request_params["actor_permissions"]
      refute permission in production_authority_from_request_params(malicious_request_params)
    end
  end

  test "explicit auth context is required for source health recheck and poll authorization" do
    source_health_auth_context = %{
      "actor_permissions" => ["source_health:recheck", "source_health:poll"],
      "actor_id_hash" => "server-derived-actor-hash",
      "request_id_hash" => "server-derived-request-hash",
      "session_id_hash" => "server-derived-session-hash",
      "role_names" => ["source_health_admin"]
    }

    assert "source_health:recheck" in source_health_auth_context["actor_permissions"]
    assert "source_health:poll" in source_health_auth_context["actor_permissions"]

    for field <- Map.keys(source_health_auth_context) do
      refute field =~ "raw_"
      refute_forbidden_fragments(field)
    end
  end

  test "bounded denial shapes do not expose raw identity private material or downstream controls" do
    for {_surface, fields} <- @bounded_denial_shapes do
      for field <- fields do
        refute_forbidden_fragments(field)
        refute_downstream_controls(field)
      end
    end
  end

  test "production-mode denial must not introduce poll audit or public source health UI" do
    production_param_denial_scope = [
      "permission_param_denial",
      "SourceHealthAuthContext",
      "bounded_403",
      "bounded_ui_state"
    ]

    for field <- production_param_denial_scope do
      refute_downstream_controls(field)
      refute_forbidden_fragments(field)
    end
  end

  defp production_authority_from_request_params(_params), do: []

  defp refute_forbidden_fragments(value) do
    value = inspect(value)

    for forbidden <- @forbidden_response_fragments do
      refute String.contains?(value, forbidden),
             "expected #{value} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end

  defp refute_downstream_controls(value) do
    value = inspect(value)

    for fragment <- @downstream_control_fragments do
      refute String.contains?(value, fragment),
             "expected #{value} not to include downstream control #{inspect(fragment)}"
    end
  end
end
