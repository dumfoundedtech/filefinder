defmodule FileFinderWeb.Api.ShopView do
  use FileFinderWeb, :view

  def render("results.json", %{results: results}) do
    %{
      inserted: Enum.map(results.inserted, fn file -> file.id end),
      updated: Enum.map(results.updated, fn file -> file.id end),
      deleted: Enum.map(results.deleted, fn file -> file.id end)
    }
  end
end
