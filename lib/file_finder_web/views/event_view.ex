defmodule FileFinderWeb.EventsView do
  use FileFinderWeb, :view

  def render("event.json", %{data: data, topic: topic}) do
    %{status: :ok, data: data, topic: topic}
  end

  def render("error.json", %{error: error, topic: topic}) do
    %{status: :error, error: error, topic: topic}
  end
end
