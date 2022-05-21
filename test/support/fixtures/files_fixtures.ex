defmodule FileFinder.FilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FileFinder.Files` context.
  """

  @doc """
  Generate a dir.
  """
  def dir_fixture(attrs \\ %{}) do
    {:ok, dir} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> FileFinder.Files.create_dir()

    dir
  end
end
