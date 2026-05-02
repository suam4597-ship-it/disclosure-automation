defmodule DisclosureAutomation.Stage57InternalSourceHealthProjectionTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Runtime.Stage57InternalSourceHealthProjection
  alias DisclosureAutomation.Sources

  @source_key "stage57_operator_view_projection_fixture"

  setup do
    {:ok, source} = Sources.upsert_source(source_attrs())

    {:ok, _cursor} =
      Sources.upsert_source_cursor(
        source,
        "latest_operator_view_projection_seen",
        "2026-05-02T00:00:00Z|stage57",
        %{"mode" => "stage57_operator_view_projection_test"}
      )

    %{source: source}
  end

  test "lists source health through redacted operator projection", %{source: source} do
    assert {:ok, page} = Stage57InternalSourceHealthProjection.list(%{"health_status" => "healthy"})

    projection = Enum.find(page.data, &(&1.fields.source_key == @source_key))

    assert projection
    assert page.view_scope == "operator_only"
    assert page.read_only == true
    assert page.advisory_only == true
    assert page.public_response_shape_mutation == false
    assert page.trigger_live_fetch == false
    assert page.scheduler_enabled == false
    assert page.source_health_mutation == false
    assert page.canonical_feed_mutation == false
    assert page.page >= 1
    assert page.page_size >= 1
    assert page.total_entries >= 1

    assert projection.view_scope == "operator_only"
    assert projection.read_only == true
    assert projection.advisory_only == true
    assert projection.public_response_shape_mutation == false
    assert projection.trigger_live_fetch == false
    assert projection.scheduler_enabled == false
    assert projection.source_health_mutation == false
    assert projection.canonical_feed_mutation == false
    assert projection.provider_canonical_feed_item_creation == false
    assert projection.news_only_event_creation == false
    assert projection.health_status == "healthy"

    assert projection.fields.source_key == @source_key
    assert projection.fields.display_name == "Stage 5.7 Operator View Projection Fixture"
    assert projection.fields.provider == "stage57_operator_view_projection_fixture_v1"
    assert projection.fields.source_type == "api"
    assert projection.fields.active == true
    assert projection.fields.health_status == "healthy"
    assert projection.fields.redaction_status == "passed"
    assert projection.fields.manual_review_reason == "operator_view_smoke"
    assert projection.fields.request_id_hash == "sha256:stage57-operator-view"
    assert projection.fields.has_recent_safe_overlay == false
    assert projection.fields.has_visible_overlays == false
    refute Map.has_key?(projection.fields, :config)
    refute Map.has_key?(projection.fields, :last_error)

    assert {:ok, after_source} = Sources.get_source_by_key(@source_key)
    assert after_source.health_status == source.health_status
    assert after_source.last_error == source.last_error
  end

  test "gets source health detail with cursor keys" do
    assert {:ok, projection} = Stage57InternalSourceHealthProjection.get(@source_key)

    assert projection.fields.source_key == @source_key
    assert projection.fields.cursor_keys == ["latest_operator_view_projection_seen"]
    assert projection.fields.health_status == "healthy"
    assert projection.fields.redaction_status == "passed"
    assert projection.fields.request_id_hash == "sha256:stage57-operator-view"
  end

  test "read-only options reject public exposure, live fetch, scheduler, and mutation" do
    assert Stage57InternalSourceHealthProjection.list(%{}, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage57_source_health_projection}

    assert Stage57InternalSourceHealthProjection.list(%{}, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage57_source_health_projection}

    assert Stage57InternalSourceHealthProjection.list(%{}, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage57_source_health_projection}

    assert Stage57InternalSourceHealthProjection.list(%{}, source_health_mutation: true) ==
             {:error, :source_health_mutation_not_allowed_in_stage57_source_health_projection}
  end

  test "missing source returns not found without side effects" do
    assert Stage57InternalSourceHealthProjection.get("missing_stage57_source") == {:error, :not_found}
  end

  defp source_attrs do
    %{
      "source_key" => @source_key,
      "display_name" => "Stage 5.7 Operator View Projection Fixture",
      "source_type" => "api",
      "adapter_key" => "stage57_operator_view_projection_fixture_v1",
      "region_code" => "jp",
      "discovery_mode" => "fixture",
      "hydrate_mode" => "local_fixture",
      "default_home_market_region_code" => "jp",
      "source_class" => "regulatory_filing_feed",
      "default_source_tier" => "reputable_news_source",
      "base_url" => "https://example.com/stage57-operator-view",
      "healthcheck_url" => "https://example.com/",
      "parser_key" => "stage57_operator_view_projection_fixture_v1",
      "poll_cron" => "*/15 * * * *",
      "coverage_tags" => ["jp", "operator_view", "stage57"],
      "active" => true,
      "health_status" => "healthy",
      "config" => %{
        "redaction_status" => "passed",
        "manual_review_reason" => "operator_view_smoke",
        "request_id_hash" => "sha256:stage57-operator-view"
      }
    }
  end
end
