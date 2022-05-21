defmodule FileFinderWeb.DirController do
  use FileFinderWeb, :controller

  alias FileFinder.Files
  alias FileFinder.Files.Dir

  def index(conn, _params) do
    dirs = Files.list_dirs()
    render(conn, "index.html", dirs: dirs)
  end

  def new(conn, _params) do
    changeset = Files.change_dir(%Dir{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"dir" => dir_params}) do
    case Files.create_dir(dir_params) do
      {:ok, dir} ->
        conn
        |> put_flash(:info, "Dir created successfully.")
        |> redirect(to: Routes.dir_path(conn, :show, dir))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    dir = Files.get_dir!(id)
    render(conn, "show.html", dir: dir)
  end

  def edit(conn, %{"id" => id}) do
    dir = Files.get_dir!(id)
    changeset = Files.change_dir(dir)
    render(conn, "edit.html", dir: dir, changeset: changeset)
  end

  def update(conn, %{"id" => id, "dir" => dir_params}) do
    dir = Files.get_dir!(id)

    case Files.update_dir(dir, dir_params) do
      {:ok, dir} ->
        conn
        |> put_flash(:info, "Dir updated successfully.")
        |> redirect(to: Routes.dir_path(conn, :show, dir))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", dir: dir, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    dir = Files.get_dir!(id)
    {:ok, _dir} = Files.delete_dir(dir)

    conn
    |> put_flash(:info, "Dir deleted successfully.")
    |> redirect(to: Routes.dir_path(conn, :index))
  end
end
