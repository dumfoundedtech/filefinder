defmodule FileFinderWeb.ShopController do
  use FileFinderWeb, :controller

  alias FileFinder.Shops
  alias FileFinder.Shops.Shop

  def index(conn, _params) do
    shops = Shops.list_shops()
    render(conn, "index.html", shops: shops)
  end

  def new(conn, _params) do
    changeset = Shops.change_shop(%Shop{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"shop" => shop_params}) do
    case Shops.create_shop(shop_params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "Shop created successfully.")
        |> redirect(to: Routes.shop_path(conn, :show, shop))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    shop = Shops.get_shop!(id)
    render(conn, "show.html", shop: shop)
  end

  def edit(conn, %{"id" => id}) do
    shop = Shops.get_shop!(id)
    changeset = Shops.change_shop(shop)
    render(conn, "edit.html", shop: shop, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop" => shop_params}) do
    shop = Shops.get_shop!(id)

    case Shops.update_shop(shop, shop_params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "Shop updated successfully.")
        |> redirect(to: Routes.shop_path(conn, :show, shop))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", shop: shop, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    shop = Shops.get_shop!(id)
    {:ok, _shop} = Shops.delete_shop(shop)

    conn
    |> put_flash(:info, "Shop deleted successfully.")
    |> redirect(to: Routes.shop_path(conn, :index))
  end
end
