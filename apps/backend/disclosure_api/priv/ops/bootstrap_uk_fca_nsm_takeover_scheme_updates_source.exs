alias DisclosureAutomation.Bootstrap
alias DisclosureAutomation.Ops.UKFCANSMTakeoverSchemeUpdatesSource
alias DisclosureAutomation.Sources

:ok = Bootstrap.bootstrap()

case Sources.upsert_source(UKFCANSMTakeoverSchemeUpdatesSource.attrs()) do
  {:ok, source} ->
    family = source.config["family"] || source.config[:family] || "takeover_or_scheme_update"

    IO.puts("upserted isolated UK FCA NSM takeover/scheme source sample for #{source.source_key}")
    IO.inspect(family, label: "family")
    IO.puts("restore the default bootstrap sample afterwards with: mix run -e \"DisclosureAutomation.Bootstrap.bootstrap()\"")

  {:error, changeset} ->
    IO.puts("failed to upsert isolated UK FCA NSM takeover/scheme source sample")
    IO.inspect(changeset, label: "changeset")
    exit({:shutdown, 1})
end
