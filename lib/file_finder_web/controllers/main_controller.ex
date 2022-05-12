defmodule FileFinderWeb.MainController do
  use FileFinderWeb, :controller

  def index(conn, _params) do
    shop_id = get_session(conn, :shop_id)

    if shop_id do
      shop = FileFinder.Shops.get_shop!(shop_id)

      conn
      |> assign(:shop_name, shop.name)
      |> assign(:token, Phoenix.Token.sign(conn, shop.name, shop_id))
      |> render("index.html")
    else
      raise FileFinderWeb.AuthError, "Unauthorized"
    end
  end
end
