defmodule FileFinderWeb.Api.DirController do
  use FileFinderWeb, :controller

  alias FileFinder.Files

  def root_shop_dirs(conn, _params) do
    shop_dirs = Files.list_shop_dirs(conn.assigns[:shop_id])
    render(conn, "shop_dirs.json", shop_dirs: shop_dirs)
  end

  def dir_shop_dirs(conn, %{"dir_id" => dir_id}) do
    shop_dirs = Files.list_shop_dirs(conn.assigns[:shop_id], dir_id)
    render(conn, "shop_dirs.json", shop_dirs: shop_dirs)
  end

  def create(conn, %{"dir" => dir_params}) do
    case Files.create_dir(dir_params) do
      {:ok, dir} ->
        render(conn, "dir.json", dir: dir)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

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
end
