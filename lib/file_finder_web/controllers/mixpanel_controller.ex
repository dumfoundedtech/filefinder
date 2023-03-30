defmodule FileFinderWeb.MixpanelController do
  use FileFinderWeb, :controller

  def lib_js(conn, _params) do
    js = HTTPoison.get("https://cdn.mxpnl.com/libs/mixpanel-2-latest.js")
    render("mixpanel.js", js: js)
  end

  def lib_min_js(conn, _params) do
    js = HTTPoison.get("https://cdn.mxpnl.com/libs/mixpanel-2-latest.min.js")
    render("mixpanel.js", js: js)
  end

  def request(conn, _params) do
    url =
      if conn.path_info |> List.first() == "decide" do
        "https://decide.mixpanel.com"
      else
        "https://api.mixpanel.com"
      end

    ip =
      cond do
        get_req_header(conn, "x-forwarded-for") |> length() > 0 ->
          get_resp_header(conn, "x-forwarded-for") |> List.first()

        get_req_header(conn, "x-real-ip") |> length() > 0 ->
          get_req_header(conn, "x-real-ip") |> List.first()

        true ->
          # TODO: format
          conn.remote_ip
      end

    render("mixpanel.json", json: %{debug: "TODO"})
  end
end
