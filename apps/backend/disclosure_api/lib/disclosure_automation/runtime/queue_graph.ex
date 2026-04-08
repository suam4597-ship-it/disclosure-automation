defmodule DisclosureAutomation.Runtime.QueueGraph do
  @moduledoc false

  @definition %{
    queues: %{
      poll: %{next: ["fetch"]},
      fetch: %{next: ["parse"]},
      parse: %{next: ["merge"]},
      merge: %{next: ["feed"]},
      feed: %{next: ["reconcile"]},
      reconcile: %{next: []},
      health: %{next: []}
    },
    default_sync_note:
      "manual poll may inline fetch/parse/merge/feed outside the merge transaction, but logical ownership remains poll -> fetch -> parse -> merge -> feed -> reconcile"
  }

  def definition, do: @definition
end
