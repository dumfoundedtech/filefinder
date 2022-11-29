defmodule FileFinderWeb.Api.FileView do
  use FileFinderWeb, :view

  def render("shop_files.json", %{shop_files: shop_files}) do
    render_many(shop_files, FileFinderWeb.Api.FileView, "file.json")
  end

  def render("file.json", %{file: file}) do
    name =
      file.url
      |> URI.parse()
      |> Map.fetch!(:path)
      |> Path.basename()
      |> String.split(".")
      |> Enum.reverse()
      |> Kernel.then(fn [h | t] ->
        Enum.reduce(t, h |> String.split("?") |> List.first(), fn part, acc ->
          "#{part}.#{acc}"
        end)
      end)

    %{
      id: file.id,
      type: file.type,
      name: name,
      url: file.url,
      preview_url: file.preview_url,
      mime_type: file.mime_type,
      dir_id: file.dir_id
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

  def render("error.json", error) do
    %{error: error}
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
