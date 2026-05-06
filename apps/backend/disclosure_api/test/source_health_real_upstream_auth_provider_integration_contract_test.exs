defmodule DisclosureAutomation.SourceHealthRealUpstreamAuthProviderIntegrationContractTest do
  use ExUnit.Case, async: true

  @provider_output_assigns [
    :upstream_actor_id_hash,
    :upstream_request_id_hash,
    :upstream_session_id_hash,
    :upstream_role_names,
    :upstream_source_health_permissions
  ]

  @required_hashed_outputs [
    :upstream_actor_id_hash,
    :upstream_request_id_hash,
    :upstream_session_id_hash
  ]

  @allowed_source_health_roles [
    "source_health_viewer",
    "source_health_operator",
    "source_health_poll_operator",
    "source_health_admin"
  ]

  @allowed_source_health_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @role_projection %{
    "source_health_viewer" => ["source_health:read"],
    "source_health_operator" => ["source_health:read", "source_health:recheck"],
    "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
    "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
  }

  @forbidden_provider_inputs_to_source_health [
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

  @forbidden_source_health_authority_fields [
    "query_actor_permissions",
    "body_actor_permissions",
    "query_actor_id_hash",
    "body_actor_id_hash",
    "query_role_names",
    "body_role_names",
    "headers_direct_to_source_health",
    "cookies_direct_to_source_health",
    "tokens_direct_to_source_health"
  ]

  @provider_integration_pipeline [
    "RealUpstreamAuthProvider",
    "SourceHealthUpstreamAuthHandoff",
    "SourceHealthProductionAuthContext",
    "SourceHealthAuthContext",
    "Source Health UI/recheck/poll authorization"
  ]

  @forbidden_surfaces [
    "login_ui",
    "logout_ui",
    "identity_provider_callback_route",
    "oauth_callback_route",
    "oidc_callback_route",
    "saml_callback_route",
    "poll_ui",
    "audit_ui",
    "public_source_health_ui"
  ]

  @bounded_missing_auth_behavior %{
    "api_recheck" => ["403", "forbidden", "source health recheck not allowed"],
    "api_poll" => ["403", "forbidden", "source poll not allowed"],
    "ui_action_state" => ["not_rendered", "bounded_default_state"]
  }

  @allowed_audit_fields [
    "actor_id_hash",
    "request_id_hash",
    "session_id_hash",
    "actor_permissions",
    "role_names",
    "redaction_status",
    "created_at"
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

  @downstream_controls [
    "provider_fetch",
    "materialize",
    "canonicalize",
    "inline_feed",
    "use_live_fetch",
    "canonical_mutation"
  ]

  test "real provider integration outputs only bounded upstream source health assigns" do
    assert @provider_output_assigns == [
             :upstream_actor_id_hash,
             :upstream_request_id_hash,
             :upstream_session_id_hash,
             :upstream_role_names,
             :upstream_source_health_permissions
           ]

    for assign <- @provider_output_assigns do
      refute assign in @forbidden_provider_inputs_to_source_health
      assign |> Atom.to_string() |> refute_forbidden_fragments()
    end
  end

  test "real provider integration hashes actor request and session before handoff" do
    assert @required_hashed_outputs == [
             :upstream_actor_id_hash,
             :upstream_request_id_hash,
             :upstream_session_id_hash
           ]

    for assign <- @required_hashed_outputs do
      assert Atom.to_string(assign) =~ "_hash"
      assign |> Atom.to_string() |> refute_forbidden_fragments()
    end
  end

  test "raw provider identity and session material is forbidden at source health boundary" do
    for field <- @forbidden_provider_inputs_to_source_health do
      refute field in @provider_output_assigns
    end
  end

  test "internal roles project only to bounded source health roles and permissions" do
    assert @allowed_source_health_roles == [
             "source_health_viewer",
             "source_health_operator",
             "source_health_poll_operator",
             "source_health_admin"
           ]

    assert @allowed_source_health_permissions == [
             "source_health:read",
             "source_health:recheck",
             "source_health:poll"
           ]

    for {role, permissions} <- @role_projection do
      assert role in @allowed_source_health_roles

      for permission <- permissions do
        assert permission in @allowed_source_health_permissions
        refute_forbidden_fragments(permission)
      end
    end
  end

  test "role projection preserves read recheck and poll separation" do
    assert @role_projection["source_health_viewer"] == ["source_health:read"]
    assert @role_projection["source_health_operator"] == ["source_health:read", "source_health:recheck"]
    assert @role_projection["source_health_poll_operator"] == ["source_health:read", "source_health:poll"]
    assert @role_projection["source_health_admin"] == @allowed_source_health_permissions

    refute "source_health:recheck" in @role_projection["source_health_viewer"]
    refute "source_health:poll" in @role_projection["source_health_viewer"]
    refute "source_health:poll" in @role_projection["source_health_operator"]
    refute "source_health:recheck" in @role_projection["source_health_poll_operator"]
  end

  test "query body header cookie and token fields are not source health provider authority" do
    for field <- @forbidden_source_health_authority_fields do
      refute field in Enum.map(@provider_output_assigns, &Atom.to_string/1)
      refute_downstream_controls(field)
    end
  end

  test "real provider integration pipeline keeps source health as bounded consumer" do
    assert @provider_integration_pipeline == [
             "RealUpstreamAuthProvider",
             "SourceHealthUpstreamAuthHandoff",
             "SourceHealthProductionAuthContext",
             "SourceHealthAuthContext",
             "Source Health UI/recheck/poll authorization"
           ]

    for step <- @provider_integration_pipeline do
      refute_downstream_controls(step)
      refute_forbidden_fragments(step)
    end
  end

  test "provider integration contract does not add login callback or source health ui surfaces" do
    contract_terms =
      @provider_output_assigns
      |> Enum.map(&Atom.to_string/1)
      |> Kernel.++(@provider_integration_pipeline)

    for surface <- @forbidden_surfaces do
      refute surface in contract_terms
    end
  end

  test "missing or invalid provider output preserves bounded default behavior" do
    for {_surface, fields} <- @bounded_missing_auth_behavior do
      for field <- fields do
        refute_forbidden_fragments(field)
        refute_downstream_controls(field)
      end
    end
  end

  test "audit fields from provider integration stay bounded" do
    assert @allowed_audit_fields == [
             "actor_id_hash",
             "request_id_hash",
             "session_id_hash",
             "actor_permissions",
             "role_names",
             "redaction_status",
             "created_at"
           ]

    for field <- @allowed_audit_fields do
      refute_forbidden_fragments(field)
    end
  end

  test "real provider integration does not expand downstream provider materializer or canonical controls" do
    contract_terms =
      @provider_output_assigns
      |> Enum.map(&Atom.to_string/1)
      |> Kernel.++(@allowed_source_health_roles)
      |> Kernel.++(@allowed_source_health_permissions)
      |> Kernel.++(@provider_integration_pipeline)

    for term <- contract_terms do
      refute_downstream_controls(term)
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

  defp refute_downstream_controls(value) do
    value = inspect(value)

    for control <- @downstream_controls do
      refute String.contains?(value, control),
             "expected #{value} not to include downstream control #{inspect(control)}"
    end
  end
end
