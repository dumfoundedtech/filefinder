defmodule FileFinderWeb.Plugs.Mixpanel do
  import Plug.Conn

  @doc false
  def init(default), do: default

  @doc false
  def call(conn, router) do
    case get_subdomain(conn.host) do
      subdomain when subdomain == "mixpanel" ->
        conn
        |> router.call(router.init({}))
        |> halt()

      _ ->
        conn
    end
  end

  defp get_subdomain(host) do
    root_host = Subdomainer.Endpoint.config(:url)[:host]
    String.replace(host, ~r/.?#{root_host}/, "")
  end
end
