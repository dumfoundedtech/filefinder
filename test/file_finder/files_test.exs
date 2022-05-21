defmodule FileFinder.FilesTest do
  use FileFinder.DataCase

  alias FileFinder.Files

  describe "dirs" do
    alias FileFinder.Files.Dir

    import FileFinder.FilesFixtures

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
      valid_attrs = %{name: "some name"}

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
end
