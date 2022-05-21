defmodule FileFinderWeb.ShopControllerTest do
  use FileFinderWeb.ConnCase

  import FileFinder.ShopsFixtures

  @create_attrs %{name: "some name", token: "some token"}
  @update_attrs %{name: "some updated name", token: "some updated token"}
  @invalid_attrs %{name: nil, token: nil}

  describe "index" do
    test "lists all shops", %{conn: conn} do
      conn = get(conn, Routes.shop_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Shops"
    end
  end

  describe "new shop" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.shop_path(conn, :new))
      assert html_response(conn, 200) =~ "New Shop"
    end
  end

  describe "create shop" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.shop_path(conn, :create), shop: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.shop_path(conn, :show, id)

      conn = get(conn, Routes.shop_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Shop"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.shop_path(conn, :create), shop: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Shop"
    end
  end

  describe "edit shop" do
    setup [:create_shop]

    test "renders form for editing chosen shop", %{conn: conn, shop: shop} do
      conn = get(conn, Routes.shop_path(conn, :edit, shop))
      assert html_response(conn, 200) =~ "Edit Shop"
    end
  end

  describe "update shop" do
    setup [:create_shop]

    test "redirects when data is valid", %{conn: conn, shop: shop} do
      conn = put(conn, Routes.shop_path(conn, :update, shop), shop: @update_attrs)
      assert redirected_to(conn) == Routes.shop_path(conn, :show, shop)

      conn = get(conn, Routes.shop_path(conn, :show, shop))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, shop: shop} do
      conn = put(conn, Routes.shop_path(conn, :update, shop), shop: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Shop"
    end
  end

  describe "delete shop" do
    setup [:create_shop]

    test "deletes chosen shop", %{conn: conn, shop: shop} do
      conn = delete(conn, Routes.shop_path(conn, :delete, shop))
      assert redirected_to(conn) == Routes.shop_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.shop_path(conn, :show, shop))
      end
    end
  end

  defp create_shop(_) do
    shop = shop_fixture()
    %{shop: shop}
  end
end
