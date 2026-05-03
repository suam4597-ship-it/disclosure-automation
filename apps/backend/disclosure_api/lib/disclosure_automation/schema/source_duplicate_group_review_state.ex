defmodule DisclosureAutomation.Schema.SourceDuplicateGroupReviewState do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @review_states ~w(unknown confirmed_by_operator rejected_by_operator needs_review cleared)

  @action_operations ~w(
    confirm_duplicate_group
    reject_duplicate_group
    mark_duplicate_group_needs_review
    clear_duplicate_group_review_state
  )

  @redaction_statuses ~w(passed failed blocked unknown)

  @required_fields ~w(group_id review_state redaction_status)a

  @prohibited_key_fragments [
    "actorid",
    "actorname",
    "actoremail",
    "requestid",
    "idempotencykey",
    "operatorreason",
    "operatornote",
    "articlebody",
    "fulltext",
    "fullarticletext",
    "rawhtml",
    "rawresponsebody",
    "responsebody",
    "providerresponsebody",
    "requestheaders",
    "responseheaders",
    "headers",
    "credentials",
    "apikey",
    "api_key",
    "authorization",
    "cookie",
    "subscriptionkey",
    "subscription-key",
    "bearertoken",
    "bearer_token",
    "signedprivateurl",
    "signed_private_url",
    "canonicalfeeditempayload",
    "providercanonicalcreationpayload",
    "canonicaleventpayload",
    "rawbodysimilaritypayload",
    "fulltextsimilaritypayload"
  ]

  schema "source_duplicate_group_review_states" do
    field :group_id, :string
    field :review_state, :string
    field :last_action_operation, :string
    field :last_action_request_id_hash, :string
    field :last_action_idempotency_key_hash, :string
    field :reviewed_by_actor_id_hash, :string
    field :reviewed_at, :utc_datetime_usec
    field :review_reason_redacted, :string
    field :redaction_status, :string

    timestamps(type: :utc_datetime_usec)
  end

  def review_states, do: @review_states
  def action_operations, do: @action_operations
  def redaction_statuses, do: @redaction_statuses

  def changeset(review_state, attrs) do
    review_state
    |> cast(attrs, [
      :group_id,
      :review_state,
      :last_action_operation,
      :last_action_request_id_hash,
      :last_action_idempotency_key_hash,
      :reviewed_by_actor_id_hash,
      :reviewed_at,
      :review_reason_redacted,
      :redaction_status
    ])
    |> reject_forbidden_attrs(attrs)
    |> validate_required(@required_fields)
    |> validate_not_blank(:group_id)
    |> validate_length(:group_id, max: 160)
    |> validate_inclusion(:review_state, @review_states)
    |> validate_optional_inclusion(:last_action_operation, @action_operations)
    |> validate_hash_field(:last_action_request_id_hash)
    |> validate_hash_field(:last_action_idempotency_key_hash)
    |> validate_hash_field(:reviewed_by_actor_id_hash)
    |> validate_length(:review_reason_redacted, max: 500)
    |> validate_no_secret_value(:review_reason_redacted)
    |> validate_inclusion(:redaction_status, @redaction_statuses)
    |> unique_constraint(:group_id, name: :source_duplicate_group_review_states_group_id_unique_idx)
  end

  defp validate_optional_inclusion(changeset, field, allowed_values) do
    validate_change(changeset, field, fn ^field, value ->
      cond do
        is_nil(value) -> []
        is_binary(value) and String.trim(value) == "" -> []
        value in allowed_values -> []
        true -> [{field, "is invalid"}]
      end
    end)
  end

  defp validate_hash_field(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      cond do
        is_nil(value) -> []
        is_binary(value) and String.trim(value) == "" -> []
        is_binary(value) and String.length(value) <= 128 and String.starts_with?(value, "sha256:") and not prohibited_value?(value) -> []
        true -> [{field, "must be a bounded sha256 hash"}]
      end
    end)
  end

  defp validate_no_secret_value(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      if is_binary(value) and prohibited_value?(value) do
        [{field, "contains prohibited value"}]
      else
        []
      end
    end)
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

  defp reject_forbidden_attrs(changeset, attrs) do
    case find_prohibited_field(attrs) do
      nil -> changeset
      path -> add_error(changeset, :base, "prohibited field #{path}")
    end
  end

  defp find_prohibited_field(value, path \\ "")

  defp find_prohibited_field(%{} = map, path) do
    Enum.find_value(map, fn {key, value} ->
      key_string = to_string(key)
      current_path = if path == "", do: key_string, else: "#{path}.#{key_string}"

      cond do
        allowed_key?(key_string) -> find_prohibited_field(value, current_path)
        prohibited_key?(key_string) -> current_path
        true -> find_prohibited_field(value, current_path)
      end
    end)
  end

  defp find_prohibited_field(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} -> find_prohibited_field(value, "#{path}[#{index}]") end)
  end

  defp find_prohibited_field(value, path) when is_binary(value) do
    if prohibited_value?(value), do: path, else: nil
  end

  defp find_prohibited_field(_value, _path), do: nil

  defp allowed_key?(key) do
    key in [
      "group_id",
      "review_state",
      "last_action_operation",
      "last_action_request_id_hash",
      "last_action_idempotency_key_hash",
      "reviewed_by_actor_id_hash",
      "reviewed_at",
      "review_reason_redacted",
      "redaction_status"
    ]
  end

  defp prohibited_key?(key) do
    normalized = normalize_token(key)

    Enum.any?(@prohibited_key_fragments, fn fragment ->
      String.contains?(normalized, normalize_token(fragment))
    end)
  end

  defp prohibited_value?(value) do
    String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, sensitive_header_prefix(:authorization)) or
      String.contains?(value, sensitive_header_prefix(:cookie)) or
      String.contains?(value, sensitive_header_prefix(:subscription_key))
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
  defp sensitive_header_prefix(:subscription_key), do: "Subscription" <> "-" <> "Key" <> ":"

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
