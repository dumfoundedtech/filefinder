defmodule FileFinderWeb.MixpanelView do
  use FileFinderWeb, :view

  def render("mixpanel.js", %{js: js}) do
    js
  end

  def render("mixpanel.json", %{json: json}) do
    json
  end
end
