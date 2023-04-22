defmodule FileFinderWeb.PageController do
  use FileFinderWeb, :controller
  alias FileFinder.Shops

  def index(conn, _params) do
    shops = Shops.list_shops()
    render(conn, "index.html", shops: shops)
  end

  def switch(conn, %{"switch" => switch}) do
    shop = Shops.get_shop!(switch["shop"])

    conn
    |> put_session(:shop_id, shop.id)
    |> redirect(to: "/")
  end
end
