defmodule DisclosureAutomation.SourceHealthUpstreamAuthHandoffContractTest do
  use ExUnit.Case, async: true

  @handoff_assigns [
    :source_health_actor_id_hash,
    :source_health_request_id_hash,
    :source_health_session_id_hash,
    :source_health_role_names,
    :source_health_permissions
  ]

  @required_hash_assigns [
    :source_health_actor_id_hash,
    :source_health_request_id_hash,
    :source_health_session_id_hash
  ]

  @role_names [
    "source_health_viewer",
    "source_health_operator",
    "source_health_poll_operator",
    "source_health_admin"
  ]

  @source_health_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @role_permission_projection %{
    "source_health_viewer" => ["source_health:read"],
    "source_health_operator" => ["source_health:read", "source_health:recheck"],
    "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
    "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
  }

  @forbidden_handoff_fields [
    :raw_actor_id,
    :raw_user_id,
    :raw_session_id,
    :raw_request_id,
    :email,
    :headers,
    :cookies,
    :tokens,
    :provider_credentials,
    :private_actor_context
  ]

  @forbidden_request_authority_fields [
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

  @source_health_routes [
    "/admin/source-health",
    "/admin/source-health/:source_key",
    "/api/admin/source-health",
    "/api/admin/source-health/:source_key",
    "/api/admin/source-health/:source_key/recheck",
    "/api/admin/sources/:source_key/poll"
  ]

  @forbidden_ui_surfaces [
    "login_ui",
    "logout_ui",
    "poll_ui",
    "audit_ui",
    "public_source_health_ui",
    "identity_provider_callback_route"
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

  @allowed_audit_handoff_fields [
    "actor_id_hash",
    "request_id_hash",
    "session_id_hash",
    "actor_permissions",
    "role_names",
    "redaction_status",
    "created_at"
  ]

  test "upstream handoff assigns are exactly bounded source health assigns" do
    assert @handoff_assigns == [
             :source_health_actor_id_hash,
             :source_health_request_id_hash,
             :source_health_session_id_hash,
             :source_health_role_names,
             :source_health_permissions
           ]

    for assign <- @handoff_assigns do
      refute assign in @forbidden_handoff_fields
      assign |> Atom.to_string() |> refute_forbidden_fragments()
    end
  end

  test "actor request and session handoff values must be hashed before source health" do
    assert @required_hash_assigns == [
             :source_health_actor_id_hash,
             :source_health_request_id_hash,
             :source_health_session_id_hash
           ]

    for assign <- @required_hash_assigns do
      assert Atom.to_string(assign) =~ "_hash"
      assign |> Atom.to_string() |> refute_forbidden_fragments()
    end
  end

  test "raw upstream identity material is forbidden in source health handoff" do
    for field <- @forbidden_handoff_fields do
      refute field in @handoff_assigns
    end
  end

  test "role names are bounded to source health role vocabulary" do
    assert @role_names == [
             "source_health_viewer",
             "source_health_operator",
             "source_health_poll_operator",
             "source_health_admin"
           ]

    for role_name <- @role_names do
      assert String.starts_with?(role_name, "source_health_")
      refute_forbidden_fragments(role_name)
    end
  end

  test "role projection preserves read recheck and poll separation" do
    assert @role_permission_projection["source_health_viewer"] == ["source_health:read"]
    assert @role_permission_projection["source_health_operator"] == [
             "source_health:read",
             "source_health:recheck"
           ]

    assert @role_permission_projection["source_health_poll_operator"] == [
             "source_health:read",
             "source_health:poll"
           ]

    assert @role_permission_projection["source_health_admin"] == @source_health_permissions

    refute "source_health:recheck" in @role_permission_projection["source_health_viewer"]
    refute "source_health:poll" in @role_permission_projection["source_health_viewer"]
    refute "source_health:poll" in @role_permission_projection["source_health_operator"]
    refute "source_health:recheck" in @role_permission_projection["source_health_poll_operator"]
  end

  test "request body and query fields are not upstream handoff authority" do
    for field <- @forbidden_request_authority_fields do
      refute field in Enum.map(@handoff_assigns, &Atom.to_string/1)
      refute_forbidden_fragments(field)
    end
  end

  test "source health route handoff uses existing route surfaces only" do
    assert @source_health_routes == [
             "/admin/source-health",
             "/admin/source-health/:source_key",
             "/api/admin/source-health",
             "/api/admin/source-health/:source_key",
             "/api/admin/source-health/:source_key/recheck",
             "/api/admin/sources/:source_key/poll"
           ]

    for route <- @source_health_routes do
      refute route =~ "/login"
      refute route =~ "/logout"
      refute route =~ "/oauth"
      refute route =~ "/saml"
      refute route =~ "/public/source-health"
      refute_forbidden_fragments(route)
    end
  end

  test "upstream handoff contract does not add ui or identity provider surfaces" do
    handoff_scope =
      @handoff_assigns
      |> Enum.map(&Atom.to_string/1)
      |> Kernel.++(@source_health_routes)

    for forbidden <- @forbidden_ui_surfaces do
      refute forbidden in handoff_scope
    end
  end

  test "audit handoff fields stay bounded and hash based" do
    assert @allowed_audit_handoff_fields == [
             "actor_id_hash",
             "request_id_hash",
             "session_id_hash",
             "actor_permissions",
             "role_names",
             "redaction_status",
             "created_at"
           ]

    for field <- @allowed_audit_handoff_fields do
      refute_forbidden_fragments(field)
    end
  end

  test "missing handoff preserves bounded default behavior contract" do
    missing_handoff_contract = %{
      "api_recheck" => ["403", "forbidden"],
      "api_poll" => ["403", "forbidden"],
      "ui_action_state" => ["not_rendered", "bounded_default_state"]
    }

    for {_surface, fields} <- missing_handoff_contract do
      for field <- fields do
        refute_forbidden_fragments(field)
      end
    end
  end

  test "handoff contract does not expand downstream provider materializer or canonical controls" do
    handoff_contract_terms =
      @handoff_assigns
      |> Enum.map(&Atom.to_string/1)
      |> Kernel.++(@role_names)
      |> Kernel.++(@source_health_permissions)
      |> Kernel.++(@source_health_routes)

    for term <- handoff_contract_terms do
      refute term =~ "provider_fetch"
      refute term =~ "materialize"
      refute term =~ "canonicalize"
      refute term =~ "inline_feed"
      refute term =~ "use_live_fetch"
      refute term =~ "canonical_mutation"
      refute_forbidden_fragments(term)
    end
  end

  defp refute_forbidden_fragments(value) do
    value = inspect(value)

    for forbidden <- @forbidden_response_fragments do
      refute String.contains?(value, forbidden),
             "expected #{value} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
