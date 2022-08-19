defmodule FileFinderWeb.Api.FileView do
  use FileFinderWeb, :view

  def render("index.json", %{files: files}) do
    render_many(files, FileFinderWeb.ApiFileView, "file.json")
  end

  def render("file.json", %{api_file: file}) do
    # TODO: name
    %{
      id: file.id,
      name: "",
      preview_url: file.preview_url,
      url: file.url,
      dir_id: file.dir_id
    }
  end
end
