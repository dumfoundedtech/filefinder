defmodule FileFinderWeb.PageControllerTest do
  use FileFinderWeb.ConnCase

  test "GET /admin", %{conn: conn} do
    conn = get(conn, "/admin")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
