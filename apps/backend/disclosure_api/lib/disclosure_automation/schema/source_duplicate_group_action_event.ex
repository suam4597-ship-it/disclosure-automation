defmodule DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @action_operations ~w(
    confirm_duplicate_group
    reject_duplicate_group
    mark_duplicate_group_needs_review
    clear_duplicate_group_review_state
  )

  @permission_by_operation %{
    "confirm_duplicate_group" => "duplicate_group:confirm",
    "reject_duplicate_group" => "duplicate_group:reject",
    "mark_duplicate_group_needs_review" => "duplicate_group:mark_review",
    "clear_duplicate_group_review_state" => "duplicate_group:clear_review_state"
  }

  @result_statuses ~w(pending accepted denied rejected failed completed skipped)
  @review_states ~w(unknown confirmed_by_operator rejected_by_operator needs_review cleared)
  @redaction_statuses ~w(passed failed blocked unknown)

  @required_fields ~w(
    group_id
    action_operation
    required_permission
    actor_id_hash
    request_id_hash
    idempotency_key_hash
    operator_reason_redacted
    result_status
    redaction_status
  )a

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

  schema "source_duplicate_group_action_events" do
    field :group_id, :string
    field :action_operation, :string
    field :required_permission, :string
    field :actor_id_hash, :string
    field :request_id_hash, :string
    field :idempotency_key_hash, :string
    field :operator_reason_redacted, :string
    field :result_status, :string
    field :pre_review_state, :string
    field :post_review_state, :string
    field :failure_code, :string
    field :redaction_status, :string

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def action_operations, do: @action_operations
  def result_statuses, do: @result_statuses
  def review_states, do: @review_states
  def redaction_statuses, do: @redaction_statuses
  def required_permission_for(operation), do: Map.get(@permission_by_operation, operation)

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :group_id,
      :action_operation,
      :required_permission,
      :actor_id_hash,
      :request_id_hash,
      :idempotency_key_hash,
      :operator_reason_redacted,
      :result_status,
      :pre_review_state,
      :post_review_state,
      :failure_code,
      :redaction_status
    ])
    |> reject_forbidden_attrs(attrs)
    |> validate_required(@required_fields)
    |> validate_not_blank(:group_id)
    |> validate_length(:group_id, max: 160)
    |> validate_inclusion(:action_operation, @action_operations)
    |> validate_required_permission_match()
    |> validate_hash_field(:actor_id_hash)
    |> validate_hash_field(:request_id_hash)
    |> validate_hash_field(:idempotency_key_hash)
    |> validate_length(:operator_reason_redacted, max: 500)
    |> validate_no_secret_value(:operator_reason_redacted)
    |> validate_inclusion(:result_status, @result_statuses)
    |> validate_optional_inclusion(:pre_review_state, @review_states)
    |> validate_optional_inclusion(:post_review_state, @review_states)
    |> validate_length(:failure_code, max: 120)
    |> validate_no_secret_value(:failure_code)
    |> validate_inclusion(:redaction_status, @redaction_statuses)
    |> unique_constraint([:group_id, :action_operation, :actor_id_hash, :idempotency_key_hash],
      name: :source_duplicate_group_action_events_idempotency_unique_idx
    )
  end

  defp validate_required_permission_match(changeset) do
    validate_change(changeset, :required_permission, fn :required_permission, permission ->
      operation = get_field(changeset, :action_operation)
      expected_permission = required_permission_for(operation)

      cond do
        is_nil(operation) -> []
        is_nil(expected_permission) -> []
        permission == expected_permission -> []
        true -> [required_permission: "does not match action operation"]
      end
    end)
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
      "action_operation",
      "required_permission",
      "actor_id_hash",
      "request_id_hash",
      "idempotency_key_hash",
      "operator_reason_redacted",
      "result_status",
      "pre_review_state",
      "post_review_state",
      "failure_code",
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
