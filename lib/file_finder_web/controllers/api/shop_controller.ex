defmodule FileFinderWeb.Api.ShopController do
  use FileFinderWeb, :controller

  alias FileFinder.Shops

  def sync(conn, _params) do
    results = Shops.sync_shop_files!(conn.assigns[:shop_id])
    render(conn, "results.json", results: results)
  end
end
