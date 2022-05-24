defmodule FileFinderWeb.FileControllerTest do
  use FileFinderWeb.ConnCase

  import FileFinder.FilesFixtures
  import FileFinder.ShopsFixtures

  @create_attrs %{
    alt: "some alt",
    preview_url: "some preview_url",
    shopify_id: "some shopify_id",
    shopify_timestamp: ~U[2022-05-23 01:31:00Z],
    type: :file,
    url: "some url"
  }
  @update_attrs %{
    alt: "some updated alt",
    preview_url: "some updated preview_url",
    shopify_id: "some updated shopify_id",
    shopify_timestamp: ~U[2022-05-24 01:31:00Z],
    type: :image,
    url: "some updated url"
  }
  @invalid_attrs %{
    alt: nil,
    preview_url: nil,
    shopify_id: nil,
    shopify_timestamp: nil,
    type: nil,
    url: nil
  }

  describe "index" do
    test "lists all files", %{conn: conn} do
      conn = get(conn, Routes.file_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Files"
    end
  end

  describe "new file" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.file_path(conn, :new))
      assert html_response(conn, 200) =~ "New File"
    end
  end

  describe "create file" do
    setup [:create_shop]

    test "redirects to show when data is valid", %{conn: conn, shop: shop} do
      conn =
        post(conn, Routes.file_path(conn, :create),
          file: Map.merge(@create_attrs, %{shop_id: shop.id})
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.file_path(conn, :show, id)

      conn = get(conn, Routes.file_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show File"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.file_path(conn, :create), file: @invalid_attrs)
      assert html_response(conn, 200) =~ "New File"
    end
  end

  describe "edit file" do
    setup [:create_file]

    test "renders form for editing chosen file", %{conn: conn, test_file: file} do
      conn = get(conn, Routes.file_path(conn, :edit, file))
      assert html_response(conn, 200) =~ "Edit File"
    end
  end

  describe "update file" do
    setup [:create_file]

    test "redirects when data is valid", %{conn: conn, test_file: file} do
      conn = put(conn, Routes.file_path(conn, :update, file), file: @update_attrs)
      assert redirected_to(conn) == Routes.file_path(conn, :show, file)

      conn = get(conn, Routes.file_path(conn, :show, file))
      assert html_response(conn, 200) =~ "some updated alt"
    end

    test "renders errors when data is invalid", %{conn: conn, test_file: file} do
      conn = put(conn, Routes.file_path(conn, :update, file), file: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit File"
    end
  end

  describe "delete file" do
    setup [:create_file]

    test "deletes chosen file", %{conn: conn, test_file: file} do
      conn = delete(conn, Routes.file_path(conn, :delete, file))
      assert redirected_to(conn) == Routes.file_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.file_path(conn, :show, file))
      end
    end
  end

  defp create_file(_) do
    file = file_fixture()
    %{test_file: file}
  end

  defp create_shop(_) do
    shop = shop_fixture()
    %{shop: shop}
  end
end
