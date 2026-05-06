defmodule DisclosureAutomation.SourceHealthProductionSessionSourceContractTest do
  use ExUnit.Case, async: true

  @source_health_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @production_context_fields [
    "actor_id_hash",
    "actor_permissions",
    "request_id_hash",
    "session_id_hash",
    "role_names",
    "redaction_status",
    "created_at"
  ]

  @production_session_sources [
    "authenticated_session",
    "server_side_user_identity",
    "server_side_role_mapping",
    "server_side_permission_mapping",
    "server_derived_request_hash",
    "server_derived_session_hash",
    "server_derived_actor_hash"
  ]

  @forbidden_direct_sources [
    "query_params",
    "request_body",
    "headers_direct_to_source_health",
    "cookies_direct_to_source_health",
    "tokens_direct_to_source_health"
  ]

  @role_permission_map %{
    "source_health_viewer" => ["source_health:read"],
    "source_health_operator" => ["source_health:read", "source_health:recheck"],
    "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
    "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
  }

  @api_unauthenticated_contract %{
    "POST /api/admin/source-health/:source_key/recheck" => ["403", "forbidden"],
    "POST /api/admin/sources/:source_key/poll" => ["403", "forbidden"]
  }

  @ui_unauthenticated_contract %{
    "GET /admin/source-health" => ["bounded_list_shell", "dedicated_ui_auth_gate_future_track"],
    "GET /admin/source-health/:source_key" => ["bounded_detail_shell", "recheck_action=not_rendered"]
  }

  @allowed_audit_auth_fields [
    "actor_id_hash",
    "request_id_hash",
    "session_id_hash",
    "actor_permissions",
    "role_names",
    "redaction_status",
    "created_at"
  ]

  @forbidden_fragments [
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

  test "production context exposes only bounded source health fields" do
    assert @production_context_fields == [
             "actor_id_hash",
             "actor_permissions",
             "request_id_hash",
             "session_id_hash",
             "role_names",
             "redaction_status",
             "created_at"
           ]

    for field <- @production_context_fields do
      refute_forbidden_fragments(field)
      refute_downstream_controls(field)
    end
  end

  test "production source must be server derived and not direct request material" do
    for source <- @production_session_sources do
      refute source in @forbidden_direct_sources
      refute_forbidden_fragments(source)
    end

    assert "authenticated_session" in @production_session_sources
    assert "server_side_user_identity" in @production_session_sources
    assert "server_side_role_mapping" in @production_session_sources
    assert "server_side_permission_mapping" in @production_session_sources
  end

  test "direct request surfaces are forbidden as source health production authority" do
    for source <- @forbidden_direct_sources do
      refute source in @production_session_sources
      refute_downstream_controls(source)
    end
  end

  test "role mapping preserves read recheck and poll separation" do
    assert @role_permission_map["source_health_viewer"] == ["source_health:read"]
    assert @role_permission_map["source_health_operator"] == ["source_health:read", "source_health:recheck"]
    assert @role_permission_map["source_health_poll_operator"] == ["source_health:read", "source_health:poll"]
    assert @role_permission_map["source_health_admin"] == @source_health_permissions

    refute "source_health:recheck" in @role_permission_map["source_health_viewer"]
    refute "source_health:poll" in @role_permission_map["source_health_viewer"]
    refute "source_health:poll" in @role_permission_map["source_health_operator"]
    refute "source_health:recheck" in @role_permission_map["source_health_poll_operator"]

    for {_role, permissions} <- @role_permission_map do
      for permission <- permissions do
        assert permission in @source_health_permissions
        refute_forbidden_fragments(permission)
      end
    end
  end

  test "request body permissions cannot override production role mapping" do
    request_body = %{
      "actor_permissions" => ["source_health:read", "source_health:recheck", "source_health:poll"],
      "role_names" => ["source_health_admin"],
      "actor_id_hash" => "request-body-actor",
      "session_id_hash" => "request-body-session"
    }

    production_viewer_context = build_context_from_roles(["source_health_viewer"])

    assert request_body["actor_permissions"] == @source_health_permissions
    assert production_viewer_context["actor_permissions"] == ["source_health:read"]
    refute "source_health:recheck" in production_viewer_context["actor_permissions"]
    refute "source_health:poll" in production_viewer_context["actor_permissions"]
  end

  test "api unauthenticated convention remains bounded and response-shape preserving" do
    assert @api_unauthenticated_contract["POST /api/admin/source-health/:source_key/recheck"] == [
             "403",
             "forbidden"
           ]

    assert @api_unauthenticated_contract["POST /api/admin/sources/:source_key/poll"] == [
             "403",
             "forbidden"
           ]

    for {_route, fields} <- @api_unauthenticated_contract do
      for field <- fields do
        refute_forbidden_fragments(field)
        refute_downstream_controls(field)
      end
    end
  end

  test "ui unauthenticated convention stays bounded until dedicated ui auth gate" do
    assert @ui_unauthenticated_contract["GET /admin/source-health"] == [
             "bounded_list_shell",
             "dedicated_ui_auth_gate_future_track"
           ]

    assert @ui_unauthenticated_contract["GET /admin/source-health/:source_key"] == [
             "bounded_detail_shell",
             "recheck_action=not_rendered"
           ]

    for {_route, fields} <- @ui_unauthenticated_contract do
      for field <- fields do
        refute_forbidden_fragments(field)
        refute_downstream_controls(field)
      end
    end
  end

  test "audit auth fields stay bounded and hash based" do
    assert @allowed_audit_auth_fields == [
             "actor_id_hash",
             "request_id_hash",
             "session_id_hash",
             "actor_permissions",
             "role_names",
             "redaction_status",
             "created_at"
           ]

    for field <- @allowed_audit_auth_fields do
      assert field in @production_context_fields or field == "request_id_hash"
      refute_forbidden_fragments(field)
    end
  end

  test "missing auth context audit placeholder remains bounded" do
    missing_context_audit = %{
      "actor_permissions" => [],
      "redaction_status" => "missing_source_health_auth_context"
    }

    assert missing_context_audit["actor_permissions"] == []
    assert missing_context_audit["redaction_status"] == "missing_source_health_auth_context"

    missing_context_audit
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "production session source design does not expand downstream controls" do
    production_session_contract =
      @production_context_fields ++
        @production_session_sources ++
        Map.keys(@role_permission_map) ++
        @source_health_permissions

    for value <- production_session_contract do
      refute_downstream_controls(value)
      refute_forbidden_fragments(value)
    end
  end

  defp build_context_from_roles(role_names) do
    permissions =
      role_names
      |> Enum.flat_map(&Map.get(@role_permission_map, &1, []))
      |> Enum.uniq()
      |> Enum.filter(&(&1 in @source_health_permissions))

    %{
      "actor_id_hash" => "server-derived-actor-hash",
      "actor_permissions" => permissions,
      "request_id_hash" => "server-derived-request-hash",
      "session_id_hash" => "server-derived-session-hash",
      "role_names" => role_names,
      "redaction_status" => "passed",
      "created_at" => "2026-05-06T00:00:00Z"
    }
  end

  defp refute_forbidden_fragments(value) do
    value = inspect(value)

    for forbidden <- @forbidden_fragments do
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
