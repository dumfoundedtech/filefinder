defmodule FileFinderWeb.ApiDirController do
  use FileFinderWeb, :controller

  def index(conn, %{"shop_id" => shop_id}) do
    # TODO: check shop_id against auth
    shop =
      FileFinder.Shops.get_shop!(shop_id)
      |> FileFinder.Repo.preload(:dirs)

    render(conn, "index.json", dirs: shop.dirs)
  end
end
