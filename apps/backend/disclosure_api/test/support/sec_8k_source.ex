defmodule DisclosureAutomation.TestSupport.SEC8KSource do
  @moduledoc false

  alias DisclosureAutomation.Ops.SEC8KSource, as: SharedSEC8KSource

  def attrs, do: SharedSEC8KSource.attrs()
end
