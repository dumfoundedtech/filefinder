defmodule FileFinderWeb.EventsController do
  use FileFinderWeb, :controller

  def uninstall(%Plug.Conn{private: %{raw_body: body}} = conn, _params) do
    topic = conn.assigns[:event_topic]

    case Jason.decode(body) do
      {:ok, data} ->
        # TODO: archive shop
        shop = FileFinder.Shops.get_shop_by_name!(data.myshopify_domain)
        render(conn, "event.json", data: data, topic: topic)
      {:error, error} ->
        render(conn, "error.json", error: error, topic: topic)
    end
  end
end
