defmodule FileFinderWeb.ApiDirView do
  use FileFinderWeb, :view

  def render("index.json", %{dirs: dirs}) do
    render_many(dirs, FileFinderWeb.ApiDirView, "dir.json")
  end

  def render("dir.json", %{api_dir: dir}) do
    %{
      id: dir.id,
      name: dir.name,
      dir_id: dir.dir_id
    }
  end
end
