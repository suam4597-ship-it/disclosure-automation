defmodule Oban do
  @moduledoc """
  Minimal compatibility shim for the Phase 0 reference runtime.

  This shim exists so the lightweight mix project under `apps/backend` can keep
  worker/job module boundaries without requiring the real Oban dependency.
  """

  alias Oban.Job

  def insert(%Job{} = job), do: {:ok, job}
end
