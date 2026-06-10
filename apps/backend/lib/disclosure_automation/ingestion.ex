defmodule DisclosureAutomation.Ingestion do
  @moduledoc """
  Minimal ingestion boundary used by retention helpers during Phase 0.
  """

  def archive_raw_documents_before(%DateTime{} = cutoff) do
    {:ok, %{archived_before: cutoff, archived_count: 0, mode: :reference_runtime}}
  end
end
