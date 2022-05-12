defmodule FileFinderWeb.MainView do
  use FileFinderWeb, :view

  def flags(conn) do
    %{
      csrf_token: Plug.CSRFProtection.get_csrf_token(),
      shop_name: conn.assigns[:shop_name],
      token: conn.assigns[:token]
    }
    |> Jason.encode!()
    |> raw
  end
end
