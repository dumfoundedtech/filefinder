defmodule FileFinderWeb.EventsController do
  use FileFinderWeb, :controller

  alias FileFinder.Airtable
  alias FileFinder.Shops

  def uninstall(%Plug.Conn{private: %{raw_body: body}} = conn, _params) do
    topic = conn.assigns[:event_topic]

    case Jason.decode(body) do
      {:ok, data} ->
        shop = Shops.get_shop_by_name(data["myshopify_domain"])

        # shop side effects
        if shop do
          {:ok, _response} = Airtable.post_event(topic, data)
          {:ok, _shop} = Shops.update_shop(shop, %{active: false})
        end

        render(conn, "event.json", data: data, topic: topic)

      {:error, error} ->
        render(conn, "error.json", error: error, topic: topic)
    end
  end
end
