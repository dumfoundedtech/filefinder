defmodule FileFinderWeb.MainController do
  use FileFinderWeb, :controller

  alias FileFinder.Shops.Shop

  def index(conn, _params) do
    shop_id = get_session(conn, :shop_id)

    if shop_id do
      shop = FileFinder.Shops.get_shop!(shop_id)

      if shop.active do
        if Shop.get_current_plan(shop) do
          conn
          |> assign(:shop_id, shop.id)
          |> assign(:shop_name, shop.name)
          |> assign(:token, Phoenix.Token.sign(conn, "shop_id", shop_id))
          |> render("index.html")
        else
          case Shop.subscribe_to_plan(shop) do
            {:ok, %Neuron.Response{body: %{"data" => data}}} ->
              confirmation_url = data["appSubscriptionCreate"]["confirmationUrl"]

              conn
              |> redirect(external: confirmation_url)

            {:error, _} ->
              raise FileFinderWeb.Error, "Error subscribing to plan"
          end
        end
      else
        redirect(conn, external: "https://filefinderapp.com")
      end
    else
      redirect(conn, external: "https://filefinderapp.com")
    end
  end
end
