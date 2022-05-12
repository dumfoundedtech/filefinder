defmodule FileFinder.ShopsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FileFinder.Shops` context.
  """

  @doc """
  Generate a unique shop name.
  """
  def unique_shop_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a shop.
  """
  def shop_fixture(attrs \\ %{}) do
    {:ok, shop} =
      attrs
      |> Enum.into(%{
        name: unique_shop_name(),
        token: "some token"
      })
      |> FileFinder.Shops.create_shop()

    shop
  end
end
