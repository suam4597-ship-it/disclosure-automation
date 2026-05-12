defmodule Oban.Worker do
  @moduledoc false

  defmacro __using__(opts) do
    queue = Keyword.get(opts, :queue, :default)

    quote do
      @behaviour unquote(__MODULE__)

      def new(args, opts \\ []) when is_map(args) do
        %Oban.Job{
          queue: to_string(Keyword.get(opts, :queue, unquote(queue))),
          worker: Atom.to_string(__MODULE__),
          args: args
        }
      end

      defoverridable new: 2
    end
  end

  @callback perform(Oban.Job.t()) :: any()
end
