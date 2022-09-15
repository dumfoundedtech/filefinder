defmodule FileFinderWeb.Api.FileController do
  use FileFinderWeb, :controller

  alias FileFinder.Files
  alias FileFinder.Files.File
  alias FileFinder.Shops

  def root_shop_files(conn, _params) do
    shop_files = Files.list_shop_files(conn.assigns[:shop_id])
    render(conn, "shop_files.json", shop_files: shop_files)
  end

  def dir_shop_files(conn, %{"dir_id" => dir_id}) do
    shop_files = Files.list_shop_files(conn.assigns[:shop_id], dir_id)
    render(conn, "shop_files.json", shop_files: shop_files)
  end

  def update(conn, %{"id" => id, "file" => file_params}) do
    file = Files.get_file!(id)

    case Files.update_file(file, file_params) do
      {:ok, file} ->
        render(conn, "file.json", file: file)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    file = Files.get_file!(id)

    case Files.delete_file(file) do
      {:ok, _} ->
        shop = Shops.get_shop!(conn.assigns[:shop_id])

        with {:ok, _} <- Files.delete_file(file),
             {:ok, _} <- File.delete_shopify_file(file.shopify_id, shop) do
          render(conn, "file.json", file: file)
        else
          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "error.json", changeset: changeset)

          {:error, error} ->
            render(conn, "error.json", error)
        end
    end
  end
end
