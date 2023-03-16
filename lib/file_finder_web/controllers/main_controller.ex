defmodule FileFinderWeb.MainController do
  use FileFinderWeb, :controller

  def index(conn, _params) do
    shop_id = get_session(conn, :shop_id)

    if shop_id do
      shop = FileFinder.Shops.get_shop!(shop_id)

      if shop.active do
        conn
        |> assign(:shop_id, shop.id)
        |> assign(:shop_name, shop.name)
        |> assign(:token, Phoenix.Token.sign(conn, "shop_id", shop_id))
        |> render("index.html")
      else
        redirect(conn, external: "https://filefinderapp.com")
      end
    else
      redirect(conn, external: "https://filefinderapp.com")
    end
  end
end
