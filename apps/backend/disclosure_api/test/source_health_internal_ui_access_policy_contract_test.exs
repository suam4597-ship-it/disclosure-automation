defmodule DisclosureAutomation.SourceHealthInternalUiAccessPolicyContractTest do
  use ExUnit.Case, async: true

  @ui_routes [
    "GET /admin/source-health",
    "GET /admin/source-health/:source_key"
  ]

  @missing_context_denial [
    "Source health access denied",
    "state=forbidden",
    "reason=missing_source_health_auth_context"
  ]

  @missing_read_denial [
    "Source health access denied",
    "state=forbidden",
    "reason=missing_source_health_read_permission"
  ]

  @read_only_detail_state [
    "Source health detail",
    "state=found",
    "recheck_action=disabled",
    "recheck_reason=read_only"
  ]

  @recheck_detail_state [
    "Source health detail",
    "state=found",
    "recheck_action=enabled",
    "recheck_method=POST",
    "idempotency=required"
  ]

  @allowed_ui_permissions [
    "source_health:read",
    "source_health:recheck"
  ]

  @poll_only_permissions [
    "source_health:poll"
  ]

  @forbidden_surfaces [
    "login_ui",
    "redirect",
    "identity_provider_callback_route",
    "poll_ui",
    "audit_ui",
    "public_source_health_ui",
    "provider_fetch",
    "materialize",
    "canonicalize"
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

  test "internal UI access policy applies only to bounded source health UI routes" do
    assert @ui_routes == [
             "GET /admin/source-health",
             "GET /admin/source-health/:source_key"
           ]

    for route <- @ui_routes do
      assert route =~ "/admin/source-health"
      refute route =~ "/api/"
      refute route =~ "/public/source-health"
      refute_forbidden_fragments(route)
    end
  end

  test "missing SourceHealthAuthContext uses bounded text UI denial" do
    assert @missing_context_denial == [
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_auth_context"
           ]

    for field <- @missing_context_denial do
      refute_forbidden_fragments(field)
      refute_forbidden_surfaces(field)
    end
  end

  test "context without source_health_read uses bounded text UI denial" do
    assert @missing_read_denial == [
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_read_permission"
           ]

    for field <- @missing_read_denial do
      refute_forbidden_fragments(field)
      refute_forbidden_surfaces(field)
    end
  end

  test "read only context can view bounded list and detail with disabled recheck" do
    assert "source_health:read" in @allowed_ui_permissions

    assert @read_only_detail_state == [
             "Source health detail",
             "state=found",
             "recheck_action=disabled",
             "recheck_reason=read_only"
           ]

    refute "recheck_action=enabled" in @read_only_detail_state

    for field <- @read_only_detail_state do
      refute_forbidden_fragments(field)
      refute_forbidden_surfaces(field)
    end
  end

  test "recheck UI requires read access plus recheck permission" do
    assert "source_health:read" in @allowed_ui_permissions
    assert "source_health:recheck" in @allowed_ui_permissions

    assert @recheck_detail_state == [
             "Source health detail",
             "state=found",
             "recheck_action=enabled",
             "recheck_method=POST",
             "idempotency=required"
           ]

    for field <- @recheck_detail_state do
      refute_forbidden_fragments(field)
      refute_forbidden_surfaces(field)
    end
  end

  test "poll-only context is not enough for internal UI read access" do
    assert @poll_only_permissions == ["source_health:poll"]
    refute "source_health:read" in @poll_only_permissions
    refute "source_health:recheck" in @poll_only_permissions

    assert @missing_read_denial == [
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_read_permission"
           ]
  end

  test "query actor permissions cannot bypass UI access policy" do
    request_param_attempts = [
      "actor_permissions=source_health:read",
      "actor_permissions=source_health:recheck",
      "actor_permissions=source_health:poll"
    ]

    for attempt <- request_param_attempts do
      refute attempt in @allowed_ui_permissions
      refute_forbidden_surfaces(attempt)
    end
  end

  test "ui access policy does not introduce login redirect or public surfaces" do
    policy_terms =
      @ui_routes ++
        @missing_context_denial ++
        @missing_read_denial ++
        @read_only_detail_state ++
        @recheck_detail_state

    for term <- policy_terms do
      refute_forbidden_surfaces(term)
      refute_forbidden_fragments(term)
    end
  end

  defp refute_forbidden_fragments(value) do
    value = inspect(value)

    for fragment <- @forbidden_fragments do
      refute String.contains?(value, fragment),
             "expected #{value} not to include forbidden fragment #{inspect(fragment)}"
    end
  end

  defp refute_forbidden_surfaces(value) do
    value = inspect(value)

    for surface <- @forbidden_surfaces do
      refute String.contains?(value, surface),
             "expected #{value} not to include forbidden surface #{inspect(surface)}"
    end
  end
end
