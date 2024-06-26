defmodule FileFinderWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :file_finder

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_file_finder_key",
    signing_salt: "GGUel2VD"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :file_finder,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt site.webmanifest)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :file_finder
  end

  plug :put_raw_body

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    length: 20_000_000,
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug FileFinderWeb.Router

  defp put_raw_body(conn, _) do
    case conn.path_info do
      ["events" | _] ->
        {:ok, body, conn_} = Plug.Conn.read_body(conn)
        Plug.Conn.put_private(conn_, :raw_body, body)

      _ ->
        conn
    end
  end
end
