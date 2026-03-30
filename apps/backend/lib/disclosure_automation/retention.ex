defmodule DisclosureAutomation.Retention do
  @moduledoc false

  alias DisclosureAutomation.Ingestion

  def archive_raw_documents(days_to_keep \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days_to_keep * 24 * 60 * 60, :second)
    Ingestion.archive_raw_documents_before(cutoff)
  end
end
