defmodule FileFinderWeb.Api.FileController do
  use FileFinderWeb, :controller

  alias FileFinder.Files
  alias FileFinder.Files.File
  alias FileFinder.Shops

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
        shop = Shops.get_shop!(file.shop_id)

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

  def shop_files(conn, _params) do
    # TODO: check shop_id against auth
    shop =
      FileFinder.Shops.get_shop!(1)
      |> FileFinder.Repo.preload(:files)

    render(conn, "shop_files.json", shop_files: shop.files)
  end
end
