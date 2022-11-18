defmodule FileFinder.FilesTest do
  use FileFinder.DataCase

  alias FileFinder.Files

  describe "dirs" do
    alias FileFinder.Files.Dir

    import FileFinder.FilesFixtures
    import FileFinder.ShopsFixtures

    @invalid_attrs %{name: nil}

    test "list_dirs/0 returns all dirs" do
      dir = dir_fixture()
      assert Files.list_dirs() == [dir]
    end

    test "get_dir!/1 returns the dir with given id" do
      dir = dir_fixture()
      assert Files.get_dir!(dir.id) == dir
    end

    test "create_dir/1 with valid data creates a dir" do
      shop = shop_fixture()
      valid_attrs = %{name: "some name", shop_id: shop.id}

      assert {:ok, %Dir{} = dir} = Files.create_dir(valid_attrs)
      assert dir.name == "some name"
    end

    test "create_dir/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Files.create_dir(@invalid_attrs)
    end

    test "update_dir/2 with valid data updates the dir" do
      dir = dir_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Dir{} = dir} = Files.update_dir(dir, update_attrs)
      assert dir.name == "some updated name"
    end

    test "update_dir/2 with invalid data returns error changeset" do
      dir = dir_fixture()
      assert {:error, %Ecto.Changeset{}} = Files.update_dir(dir, @invalid_attrs)
      assert dir == Files.get_dir!(dir.id)
    end

    test "delete_dir/1 deletes the dir" do
      dir = dir_fixture()
      assert {:ok, %Dir{}} = Files.delete_dir(dir)
      assert_raise Ecto.NoResultsError, fn -> Files.get_dir!(dir.id) end
    end

    test "change_dir/1 returns a dir changeset" do
      dir = dir_fixture()
      assert %Ecto.Changeset{} = Files.change_dir(dir)
    end
  end

  describe "files" do
    alias FileFinder.Files.File

    import FileFinder.FilesFixtures
    import FileFinder.ShopsFixtures

    @invalid_attrs %{
      alt: nil,
      preview_url: nil,
      shopify_id: nil,
      shopify_timestamp: nil,
      type: nil,
      url: nil
    }

    test "list_files/0 returns all files" do
      file = file_fixture()
      assert Files.list_files() == [file]
    end

    test "get_file!/1 returns the file with given id" do
      file = file_fixture()
      assert Files.get_file!(file.id) == file
    end

    test "create_file/1 with valid data creates a file" do
      shop = shop_fixture()

      valid_attrs = %{
        alt: "some alt",
        preview_url: "some preview_url",
        shopify_id: "some shopify_id",
        shopify_timestamp: ~U[2022-05-23 01:31:00Z],
        type: :file,
        mime_type: "text/plain",
        url: "some url",
        shop_id: shop.id
      }

      assert {:ok, %File{} = file} = Files.create_file(valid_attrs)
      assert file.alt == "some alt"
      assert file.preview_url == "some preview_url"
      assert file.shopify_id == "some shopify_id"
      assert file.shopify_timestamp == ~U[2022-05-23 01:31:00Z]
      assert file.type == :file
      assert file.mime_type == "text/plain"
      assert file.url == "some url"
    end

    test "create_file/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Files.create_file(@invalid_attrs)
    end

    test "update_file/2 with valid data updates the file" do
      file = file_fixture()

      update_attrs = %{
        alt: "some updated alt",
        preview_url: "some updated preview_url",
        shopify_id: "some updated shopify_id",
        shopify_timestamp: ~U[2022-05-24 01:31:00Z],
        type: :image,
        url: "some updated url"
      }

      assert {:ok, %File{} = file} = Files.update_file(file, update_attrs)
      assert file.alt == "some updated alt"
      assert file.preview_url == "some updated preview_url"
      assert file.shopify_id == "some updated shopify_id"
      assert file.shopify_timestamp == ~U[2022-05-24 01:31:00Z]
      assert file.type == :image
      assert file.url == "some updated url"
    end

    test "update_file/2 with invalid data returns error changeset" do
      file = file_fixture()
      assert {:error, %Ecto.Changeset{}} = Files.update_file(file, @invalid_attrs)
      assert file == Files.get_file!(file.id)
    end

    test "delete_file/1 deletes the file" do
      file = file_fixture()
      assert {:ok, %File{}} = Files.delete_file(file)
      assert_raise Ecto.NoResultsError, fn -> Files.get_file!(file.id) end
    end

    test "change_file/1 returns a file changeset" do
      file = file_fixture()
      assert %Ecto.Changeset{} = Files.change_file(file)
    end
  end
end
