defmodule DisclosureAutomation.Stage52NewsOverlayAttachmentSchemaTest do
  use DisclosureAutomationWeb.ConnCase, async: true

  alias DisclosureAutomation.Schema.NewsOverlayAttachment

  @official_item_id "11111111-1111-1111-1111-111111111111"
  @source_registry_id "22222222-2222-2222-2222-222222222222"
  @raw_document_id "33333333-3333-3333-3333-333333333333"
  @raw_event_id "44444444-4444-4444-4444-444444444444"

  @valid_attrs %{
    official_canonical_feed_item_id: @official_item_id,
    official_event_id: "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    official_stable_external_id: "TDNET:4527:20260430:1900:140120260430515474",
    overlay_source_registry_id: @source_registry_id,
    overlay_source_key: "stage5_news_overlay_fixture",
    overlay_provider: "Reuters",
    overlay_external_id: "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001",
    overlay_raw_document_id: @raw_document_id,
    overlay_raw_event_id: @raw_event_id,
    overlay_id: "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57",
    overlay_mode: "attach_only",
    display_state: "visible",
    canonical_fact_override: false,
    source_tier: "reputable_news_source",
    document_role: "news_article",
    published_at: ~U[2026-04-30 10:30:00.000000Z],
    url: "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/",
    title: "英ファンドＡＶＩ、ロートの会長解任議案を提出　企業統治改善求める",
    language: "ja",
    jurisdiction: "JP",
    overlay_payload: %{
      "provider" => "Reuters",
      "canonicalFactOverride" => false
    },
    conflict_flags: %{"items" => ["provider_url_not_official_url"]},
    overlay_claims: %{
      "items" => [
        %{
          "claim_id" => "overlay-claim-1",
          "claim_type" => "context_summary",
          "canonical_fact_override" => false
        }
      ]
    },
    citations: %{
      "items" => [
        %{
          "citation_id" => "reuters-overlay-1",
          "source_key" => "stage5_news_overlay_fixture",
          "is_canonical_source" => false
        }
      ]
    }
  }

  test "valid Stage 5.2 Reuters attachment changeset passes" do
    changeset = NewsOverlayAttachment.changeset(%NewsOverlayAttachment{}, @valid_attrs)

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :canonical_fact_override) == false
    assert Ecto.Changeset.get_field(changeset, :overlay_mode) == "attach_only"
    assert Ecto.Changeset.get_field(changeset, :source_tier) == "reputable_news_source"
    assert Ecto.Changeset.get_field(changeset, :document_role) == "news_article"
  end

  test "rejects canonical_fact_override true" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | canonical_fact_override: true})

    refute changeset.valid?
    assert error_on?(changeset, :canonical_fact_override, "must be false for Stage 5.2 v1")
  end

  test "rejects non attach-only overlay mode" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | overlay_mode: "replace_official"})

    refute changeset.valid?
    assert error_on?(changeset, :overlay_mode, "is invalid")
  end

  test "rejects unknown display state" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | display_state: "visible_after_override"})

    refute changeset.valid?
    assert error_on?(changeset, :display_state, "is invalid")
  end

  test "rejects non-reputable source tier" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | source_tier: "unverified_social_media"})

    refute changeset.valid?
    assert error_on?(changeset, :source_tier, "is invalid")
  end

  test "rejects non-news document role" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | document_role: "official_disclosure"})

    refute changeset.valid?
    assert error_on?(changeset, :document_role, "is invalid")
  end

  test "rejects blank required text identities" do
    changeset =
      %NewsOverlayAttachment{}
      |> NewsOverlayAttachment.changeset(%{@valid_attrs | overlay_id: "   "})

    refute changeset.valid?
    assert error_on?(changeset, :overlay_id, "can't be blank")
  end

  test "requires official and overlay identity fields" do
    changeset = NewsOverlayAttachment.changeset(%NewsOverlayAttachment{}, %{})

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :official_canonical_feed_item_id)
    assert Keyword.has_key?(changeset.errors, :official_event_id)
    assert Keyword.has_key?(changeset.errors, :overlay_source_key)
    assert Keyword.has_key?(changeset.errors, :overlay_provider)
    assert Keyword.has_key?(changeset.errors, :overlay_external_id)
    assert Keyword.has_key?(changeset.errors, :overlay_id)
  end

  defp error_on?(changeset, field, expected_message) do
    Enum.any?(Keyword.get_values(changeset.errors, field), fn {message, _opts} ->
      message == expected_message
    end)
  end
end
