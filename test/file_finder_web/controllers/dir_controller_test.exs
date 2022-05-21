defmodule FileFinderWeb.DirControllerTest do
  use FileFinderWeb.ConnCase

  import FileFinder.FilesFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "index" do
    test "lists all dirs", %{conn: conn} do
      conn = get(conn, Routes.dir_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Dirs"
    end
  end

  describe "new dir" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.dir_path(conn, :new))
      assert html_response(conn, 200) =~ "New Dir"
    end
  end

  describe "create dir" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.dir_path(conn, :create), dir: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.dir_path(conn, :show, id)

      conn = get(conn, Routes.dir_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Dir"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.dir_path(conn, :create), dir: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Dir"
    end
  end

  describe "edit dir" do
    setup [:create_dir]

    test "renders form for editing chosen dir", %{conn: conn, dir: dir} do
      conn = get(conn, Routes.dir_path(conn, :edit, dir))
      assert html_response(conn, 200) =~ "Edit Dir"
    end
  end

  describe "update dir" do
    setup [:create_dir]

    test "redirects when data is valid", %{conn: conn, dir: dir} do
      conn = put(conn, Routes.dir_path(conn, :update, dir), dir: @update_attrs)
      assert redirected_to(conn) == Routes.dir_path(conn, :show, dir)

      conn = get(conn, Routes.dir_path(conn, :show, dir))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, dir: dir} do
      conn = put(conn, Routes.dir_path(conn, :update, dir), dir: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Dir"
    end
  end

  describe "delete dir" do
    setup [:create_dir]

    test "deletes chosen dir", %{conn: conn, dir: dir} do
      conn = delete(conn, Routes.dir_path(conn, :delete, dir))
      assert redirected_to(conn) == Routes.dir_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.dir_path(conn, :show, dir))
      end
    end
  end

  defp create_dir(_) do
    dir = dir_fixture()
    %{dir: dir}
  end
end
