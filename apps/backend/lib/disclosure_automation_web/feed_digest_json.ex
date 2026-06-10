defmodule DisclosureAutomationWeb.FeedDigestJSON do
  @moduledoc false

  def show(%{digest: digest}), do: digest

  def error(%{code: code, message: message}) do
    %{
      error: %{
        code: code,
        message: message
      }
    }
  end
end
