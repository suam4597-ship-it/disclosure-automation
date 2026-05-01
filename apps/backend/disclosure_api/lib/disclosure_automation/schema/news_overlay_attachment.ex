defmodule DisclosureAutomation.Schema.NewsOverlayAttachment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @overlay_mode "attach_only"
  @source_tier "reputable_news_source"
  @document_role "news_article"

  @display_states [
    "visible",
    "hidden_missing_direct_official_identifier",
    "hidden_conflict_requires_review",
    "hidden_full_text_policy",
    "hidden_source_not_allowed"
  ]

  schema "news_overlay_attachments" do
    field :official_canonical_feed_item_id, :binary_id
    field :official_event_id, :string
    field :official_stable_external_id, :string
    field :overlay_source_registry_id, :binary_id
    field :overlay_source_key, :string
    field :overlay_provider, :string
    field :overlay_external_id, :string
    field :overlay_raw_document_id, :binary_id
    field :overlay_raw_event_id, :binary_id
    field :overlay_id, :string
    field :overlay_mode, :string
    field :display_state, :string
    field :canonical_fact_override, :boolean, default: false
    field :source_tier, :string
    field :document_role, :string
    field :published_at, :utc_datetime_usec
    field :url, :string
    field :title, :string
    field :language, :string
    field :jurisdiction, :string
    field :overlay_payload, :map, default: %{}
    field :conflict_flags, :map, default: %{"items" => []}
    field :overlay_claims, :map, default: %{"items" => []}
    field :citations, :map, default: %{"items" => []}

    timestamps(type: :utc_datetime_usec)
  end

  def overlay_mode, do: @overlay_mode
  def source_tier, do: @source_tier
  def document_role, do: @document_role
  def display_states, do: @display_states

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [
      :official_canonical_feed_item_id,
      :official_event_id,
      :official_stable_external_id,
      :overlay_source_registry_id,
      :overlay_source_key,
      :overlay_provider,
      :overlay_external_id,
      :overlay_raw_document_id,
      :overlay_raw_event_id,
      :overlay_id,
      :overlay_mode,
      :display_state,
      :canonical_fact_override,
      :source_tier,
      :document_role,
      :published_at,
      :url,
      :title,
      :language,
      :jurisdiction,
      :overlay_payload,
      :conflict_flags,
      :overlay_claims,
      :citations
    ])
    |> validate_required([
      :official_canonical_feed_item_id,
      :official_event_id,
      :overlay_source_key,
      :overlay_provider,
      :overlay_external_id,
      :overlay_id,
      :overlay_mode,
      :display_state,
      :canonical_fact_override,
      :source_tier,
      :document_role
    ])
    |> validate_change(:canonical_fact_override, fn
      :canonical_fact_override, false -> []
      :canonical_fact_override, _ -> [canonical_fact_override: "must be false for Stage 5.2 v1"]
    end)
    |> validate_inclusion(:overlay_mode, [@overlay_mode])
    |> validate_inclusion(:display_state, @display_states)
    |> validate_inclusion(:source_tier, [@source_tier])
    |> validate_inclusion(:document_role, [@document_role])
    |> validate_not_blank(:official_event_id)
    |> validate_not_blank(:overlay_source_key)
    |> validate_not_blank(:overlay_provider)
    |> validate_not_blank(:overlay_external_id)
    |> validate_not_blank(:overlay_id)
    |> foreign_key_constraint(:official_canonical_feed_item_id)
    |> foreign_key_constraint(:overlay_source_registry_id)
    |> foreign_key_constraint(:overlay_raw_document_id)
    |> foreign_key_constraint(:overlay_raw_event_id)
    |> unique_constraint([:official_canonical_feed_item_id, :overlay_source_key, :overlay_external_id],
      name: :news_overlay_attachments_official_overlay_external_id_uidx
    )
    |> unique_constraint([:official_event_id, :overlay_id],
      name: :news_overlay_attachments_official_event_overlay_id_uidx
    )
    |> check_constraint(:canonical_fact_override,
      name: :news_overlay_attachments_no_canonical_override
    )
    |> check_constraint(:overlay_mode, name: :news_overlay_attachments_attach_only)
    |> check_constraint(:display_state, name: :news_overlay_attachments_display_state_allowed)
    |> check_constraint(:source_tier, name: :news_overlay_attachments_source_tier_allowed)
    |> check_constraint(:document_role, name: :news_overlay_attachments_document_role_allowed)
    |> check_constraint(:official_event_id, name: :news_overlay_attachments_required_text_present)
  end

  defp validate_not_blank(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      if is_binary(value) and String.trim(value) == "" do
        [{field, "can't be blank"}]
      else
        []
      end
    end)
  end
end
