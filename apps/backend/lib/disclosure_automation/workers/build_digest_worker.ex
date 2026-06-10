defmodule DisclosureAutomation.Workers.BuildDigestWorker do
  @moduledoc false

  use Oban.Worker, queue: :digest_building, max_attempts: 5

  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Events.Contracts
  alias DisclosureAutomation.Events.Publisher

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"digest_date" => digest_date, "edition" => edition}}) do
    case Digest.get_digest_by_date_and_edition(digest_date, edition, fallback_to_fixture: true) do
      {:ok, digest} ->
        _ =
          Publisher.publish(
            "digest.edition_generated",
            "digest",
            "#{digest_date}:#{edition}",
            digest,
            %{phase: "phase0"},
            consumers: Contracts.default_consumers_for("digest.edition_generated")
          )

        :ok

      {:error, :not_found} ->
        {:cancel, :digest_not_found}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end
end
