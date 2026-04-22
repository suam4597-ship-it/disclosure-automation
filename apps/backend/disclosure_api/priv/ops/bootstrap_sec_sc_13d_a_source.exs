alias DisclosureAutomation.Bootstrap
alias DisclosureAutomation.Ops.SECSC13DASource
alias DisclosureAutomation.Sources

:ok = Bootstrap.bootstrap()

case Sources.upsert_source(SECSC13DASource.attrs()) do
  {:ok, source} ->
    supported_forms_now =
      source.config["supported_forms_now"] || source.config[:supported_forms_now] || []

    IO.puts("upserted isolated SEC SC 13D/A source sample for #{source.source_key}")
    IO.inspect(supported_forms_now, label: "supported_forms_now")
    IO.puts("restore the default bootstrap sample afterwards with: mix run -e \"DisclosureAutomation.Bootstrap.bootstrap()\"")

  {:error, changeset} ->
    IO.puts("failed to upsert isolated SEC SC 13D/A source sample")
    IO.inspect(changeset, label: "changeset")
    exit({:shutdown, 1})
end
