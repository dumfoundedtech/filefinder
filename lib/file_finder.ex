defmodule FileFinder do
  @moduledoc """
  FileFinder keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Logger

  def pass_through_debug_log(x) do
    inspect(x, pretty: true)
    |> Logger.debug()

    x
  end
end
