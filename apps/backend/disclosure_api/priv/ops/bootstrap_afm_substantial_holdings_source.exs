alias DisclosureAutomation.Bootstrap
alias DisclosureAutomation.Ops.AFMSubstantialHoldingsSource
alias DisclosureAutomation.Sources

:ok = Bootstrap.bootstrap()

case Sources.upsert_source(AFMSubstantialHoldingsSource.attrs()) do
  {:ok, source} ->
    register_kind =
      source.config["register_kind"] || source.config[:register_kind] || "substantial_holdings"

    IO.puts("upserted isolated AFM substantial holdings source sample for #{source.source_key}")
    IO.inspect(register_kind, label: "register_kind")
    IO.puts("restore the default bootstrap sample afterwards with: mix run -e \"DisclosureAutomation.Bootstrap.bootstrap()\"")

  {:error, changeset} ->
    IO.puts("failed to upsert isolated AFM substantial holdings source sample")
    IO.inspect(changeset, label: "changeset")
    exit({:shutdown, 1})
end
