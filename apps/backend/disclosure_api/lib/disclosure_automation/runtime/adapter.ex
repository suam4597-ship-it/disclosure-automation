defmodule DisclosureAutomation.Runtime.Adapter do
  @moduledoc false

  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Runtime.AFMSubstantialHoldingsAdapter
  alias DisclosureAutomation.Runtime.CNCNInfoBroadAnnouncementFeedAdapter
  alias DisclosureAutomation.Runtime.CNCNInfoOwnershipChangeAdapter
  alias DisclosureAutomation.Runtime.JPTDnetBroadTimelyDisclosureAdapter
  alias DisclosureAutomation.Runtime.JPTDnetTimelyDisclosureAdapter
  alias DisclosureAutomation.Runtime.SECAdapter
  alias DisclosureAutomation.Runtime.TWMOPSMaterialInformationAdapter
  alias DisclosureAutomation.Runtime.UKFCANSMTakeoverSchemeUpdatesAdapter

  @type source :: SourceRegistry.t()
  @type discovery_item :: map()
  @type hydrated_item :: map()
  @type raw_event :: map()
  @type canonical_item :: map()

  @callback discover(source(), keyword()) :: {:ok, [discovery_item()]} | {:error, term()}
  @callback hydrate(source(), discovery_item(), keyword()) :: {:ok, hydrated_item()} | {:error, term()}
  @callback parse(source(), hydrated_item(), keyword()) :: {:ok, [raw_event()]} | {:error, term()}
  @callback normalize(source(), raw_event(), keyword()) ::
              {:ok, canonical_item()} | {:error, term()}

  def resolve(%SourceRegistry{adapter_key: "sec_edgar_forms_v1"}), do: {:ok, SECAdapter}

  def resolve(%SourceRegistry{adapter_key: "afm_substantial_holdings_v1"}),
    do: {:ok, AFMSubstantialHoldingsAdapter}

  def resolve(%SourceRegistry{adapter_key: "uk_fca_nsm_takeover_scheme_updates_v1"}),
    do: {:ok, UKFCANSMTakeoverSchemeUpdatesAdapter}

  def resolve(%SourceRegistry{adapter_key: "tw_mops_material_information_v1"}),
    do: {:ok, TWMOPSMaterialInformationAdapter}

  def resolve(%SourceRegistry{adapter_key: "cn_cninfo_ownership_change_v1"}),
    do: {:ok, CNCNInfoOwnershipChangeAdapter}

  def resolve(%SourceRegistry{adapter_key: "cn_cninfo_broad_announcement_feed_v1"}),
    do: {:ok, CNCNInfoBroadAnnouncementFeedAdapter}

  def resolve(%SourceRegistry{adapter_key: "jp_tdnet_timely_disclosure_v1"}),
    do: {:ok, JPTDnetTimelyDisclosureAdapter}

  def resolve(%SourceRegistry{adapter_key: "jp_tdnet_broad_timely_disclosure_v1"}),
    do: {:ok, JPTDnetBroadTimelyDisclosureAdapter}

  def resolve(%SourceRegistry{adapter_key: nil}), do: :error
  def resolve(%SourceRegistry{adapter_key: _unknown}), do: :error
end
