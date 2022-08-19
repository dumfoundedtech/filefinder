defmodule FileFinderWeb.Api.DirController do
  use FileFinderWeb, :controller

  alias FileFinder.Files

  def update(conn, %{"id" => id, "dir" => dir_params}) do
    dir = Files.get_dir!(id)

    case Files.update_dir(dir, dir_params) do
      {:ok, dir} ->
        render(conn, "dir.json", dir: dir)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    dir = Files.get_dir!(id)
    {:ok, _dir} = Files.delete_dir(dir)
    render(conn, "dir.json", dir: dir)
  end

  def shop_dirs(conn, _params) do
    # TODO: check shop_id against auth
    shop =
      FileFinder.Shops.get_shop!(1)
      |> FileFinder.Repo.preload(:dirs)

    render(conn, "shop_dirs.json", shop_dirs: shop.dirs)
  end
end
