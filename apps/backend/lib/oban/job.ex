defmodule Oban.Job do
  @moduledoc false

  defstruct [:queue, :worker, args: %{}]
end
