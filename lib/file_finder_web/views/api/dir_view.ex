defmodule FileFinderWeb.Api.DirView do
  use FileFinderWeb, :view

  def render("shop_dirs.json", %{shop_dirs: shop_dirs}) do
    render_many(shop_dirs, FileFinderWeb.Api.DirView, "dir.json")
  end

  def render("dir.json", %{api_dir: dir}) do
    %{
      id: dir.id,
      name: dir.name,
      dir_id: dir.dir_id
    }
  end

  def render("error.json", %{changeset: changeset}) do
    errors =
      Enum.map(changeset.errors, fn {field, detail} ->
        %{
          source: %{pointer: "/data/attributes/#{field}"},
          title: "Invalid Attribute",
          detail: render_error_detail(detail)
        }
      end)

    %{errors: errors}
  end

  def render_error_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  def render_error_detail(message) do
    message
  end
end
