defmodule FileFinderWeb.MainController do
  use FileFinderWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
