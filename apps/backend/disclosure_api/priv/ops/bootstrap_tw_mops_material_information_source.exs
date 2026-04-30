alias DisclosureAutomation.Bootstrap
alias DisclosureAutomation.Ops.TWMOPSMaterialInformationSource
alias DisclosureAutomation.Sources

:ok = Bootstrap.bootstrap()

case Sources.upsert_source(TWMOPSMaterialInformationSource.attrs()) do
  {:ok, source} ->
    family = source.config["family"] || source.config[:family] || "material_information_update"

    IO.puts("upserted isolated TW MOPS material information source sample for #{source.source_key}")
    IO.inspect(family, label: "family")

  {:error, changeset} ->
    IO.puts("failed to upsert isolated TW MOPS material information source sample")
    IO.inspect(changeset, label: "changeset")
    exit({:shutdown, 1})
end
