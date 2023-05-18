defmodule FileFinder.Shops.BackgroundSync do
  use Oban.Worker, tags: ["shops", "background_sync"]

  alias FileFinder.Shops

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    {:ok, Shops.sync_shop_files!(id)}
  end
end
