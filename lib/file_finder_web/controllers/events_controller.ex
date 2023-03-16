defmodule FileFinderWeb.EventsController do
  use FileFinderWeb, :controller

  alias FileFinder.Airtable
  alias FileFinder.Shops

  def event(%Plug.Conn{private: %{raw_body: body}} = conn, _params) do
    topic = conn.assigns[:event_topic]
    data = Jason.decode!(body)

    # side effects
    {:ok, _response} = Airtable.post_event(topic, data)

    render(conn, "event.json", data: data, topic: topic)
  end

  def uninstall(%Plug.Conn{private: %{raw_body: body}} = conn, _params) do
    topic = conn.assigns[:event_topic]
    data = Jason.decode!(body)

    shop = Shops.get_shop_by_name(data["myshopify_domain"])

    # shop side effects
    if shop do
      {:ok, _response} = Airtable.post_event(topic, data)
      {:ok, _shop} = Shops.update_shop(shop, %{active: false})
    end

    render(conn, "event.json", data: data, topic: topic)
  end
end
