defmodule DisclosureAutomation.Schema.SourceDuplicateGroup do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @confidence_states ~w(unknown candidate likely confirmed_by_operator rejected_by_operator)
  @redaction_statuses ~w(passed failed blocked unknown)

  @match_reasons ~w(
    same_official_event_id
    same_official_stable_external_id
    same_security_code
    same_disclosure_date
    same_provider_external_id_hash
    same_title_fingerprint
    same_url_fingerprint
    same_provider_citation_target
    operator_confirmed_duplicate
  )

  @required_fields ~w(
    group_id
    confidence
    source_keys
    match_reasons
    member_count
    has_official_tdnet_event
    has_provider_overlay
    redaction_status
  )a

  @prohibited_key_fragments [
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

  schema "source_duplicate_groups" do
    field :group_id, :string
    field :confidence, :string
    field :source_keys, :map, default: %{"items" => []}
    field :match_reasons, :map, default: %{"items" => []}
    field :member_count, :integer
    field :has_official_tdnet_event, :boolean, default: false
    field :has_provider_overlay, :boolean, default: false
    field :redaction_status, :string

    timestamps(type: :utc_datetime_usec)
  end

  def confidence_states, do: @confidence_states
  def redaction_statuses, do: @redaction_statuses
  def match_reasons, do: @match_reasons

  def changeset(group, attrs) do
    group
    |> cast(attrs, [
      :group_id,
      :confidence,
      :source_keys,
      :match_reasons,
      :member_count,
      :has_official_tdnet_event,
      :has_provider_overlay,
      :redaction_status
    ])
    |> reject_forbidden_attrs(attrs)
    |> validate_required(@required_fields)
    |> validate_length(:group_id, max: 160)
    |> validate_inclusion(:confidence, @confidence_states)
    |> validate_inclusion(:redaction_status, @redaction_statuses)
    |> validate_number(:member_count, greater_than_or_equal_to: 2)
    |> validate_not_blank(:group_id)
    |> validate_items(:source_keys, nil)
    |> validate_items(:match_reasons, @match_reasons)
    |> unique_constraint(:group_id, name: :source_duplicate_groups_group_id_unique_idx)
  end

  defp validate_items(changeset, field, allowed_values) do
    validate_change(changeset, field, fn ^field, value ->
      with {:ok, items} <- extract_items(value),
           :ok <- validate_non_empty_items(items),
           :ok <- validate_bounded_items(items),
           :ok <- validate_allowed_items(items, allowed_values) do
        []
      else
        {:error, reason} -> [{field, Atom.to_string(reason)}]
      end
    end)
  end

  defp extract_items(%{"items" => items}) when is_list(items), do: {:ok, items}
  defp extract_items(%{items: items}) when is_list(items), do: {:ok, items}
  defp extract_items(_value), do: {:error, :must_have_items_list}

  defp validate_non_empty_items([]), do: {:error, :items_required}
  defp validate_non_empty_items(_items), do: :ok

  defp validate_bounded_items(items) do
    if Enum.all?(items, &(is_binary(&1) and String.trim(&1) != "" and String.length(&1) <= 128 and not prohibited_value?(&1))) do
      :ok
    else
      {:error, :items_must_be_bounded_strings}
    end
  end

  defp validate_allowed_items(_items, nil), do: :ok

  defp validate_allowed_items(items, allowed_values) do
    if Enum.all?(items, &(&1 in allowed_values)) do
      :ok
    else
      {:error, :items_not_allowlisted}
    end
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

  defp validate_not_blank(changeset, field) do
    validate_change(changeset, field, fn ^field, value ->
      if is_binary(value) and String.trim(value) == "" do
        [{field, "can't be blank"}]
      else
        []
      end
    end)
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
