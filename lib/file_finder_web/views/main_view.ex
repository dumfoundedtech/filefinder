defmodule FileFinderWeb.MainView do
  use FileFinderWeb, :view

  def flags(conn) do
    %{}
    |> Jason.encode!()
    |> raw
  end
end
