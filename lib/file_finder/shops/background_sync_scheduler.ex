defmodule FileFinder.Shops.BackgroundSyncScheduler do
  use Oban.Worker, tags: ["shops", "background_sync_scheduler"]

  alias FileFinder.Shops
  alias FileFinder.Shops.BackgroundSync

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    Shops.list_shops()
    |> Enum.each(fn shop ->
      %{id: shop.id}
      |> BackgroundSync.new(priority: 3)
      |> Oban.insert()
    end)
  end
end
