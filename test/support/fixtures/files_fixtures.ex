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

  @doc """
  Generate a unique file shopify_id.
  """
  def unique_file_shopify_id, do: "some shopify_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique file url.
  """
  def unique_file_url, do: "some url#{System.unique_integer([:positive])}"

  @doc """
  Generate a file.
  """
  def file_fixture(attrs \\ %{}) do
    shop = shop_fixture()

    {:ok, file} =
      attrs
      |> Enum.into(%{
        alt: "some alt",
        preview_url: "some preview_url",
        shopify_id: unique_file_shopify_id(),
        shopify_timestamp: ~U[2022-05-23 01:31:00Z],
        type: :file,
        url: unique_file_url(),
        shop_id: shop.id
      })
      |> FileFinder.Files.create_file()

    file
  end
end
