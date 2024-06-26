defmodule FileFinder.Shops do
  @moduledoc """
  The Shops context.
  """

  import Ecto.Query, warn: false
  alias FileFinder.Repo

  alias FileFinder.Shops.Shop

  @doc """
  Returns the list of shops.

  ## Examples

      iex> list_shops()
      [%Shop{}, ...]

  """
  def list_shops do
    Repo.all(Shop)
  end

  @doc """
  Gets a single shop.

  Raises `Ecto.NoResultsError` if the Shop does not exist.

  ## Examples

      iex> get_shop!(123)
      %Shop{}

      iex> get_shop!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shop!(id), do: Repo.get!(Shop, id)

  @doc """
  Gets a single shop by name.

  Returns nil if the Shop does not exist.

  ## Examples

      iex> get_shop_by_name("shop.myshopify.com")
      %Shop{}

      iex> get_shop_by_name("")
      nil

  """
  def get_shop_by_name(name), do: Repo.get_by(Shop, name: name)

  @doc """
  Creates a shop.

  ## Examples

      iex> create_shop(%{field: value})
      {:ok, %Shop{}}

      iex> create_shop(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_shop(attrs \\ %{}) do
    %Shop{}
    |> Shop.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a shop.

  ## Examples

      iex> update_shop(shop, %{field: new_value})
      {:ok, %Shop{}}

      iex> update_shop(shop, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shop(%Shop{} = shop, attrs) do
    shop
    |> Shop.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shop.

  ## Examples

      iex> delete_shop(shop)
      {:ok, %Shop{}}

      iex> delete_shop(shop)
      {:error, %Ecto.Changeset{}}

  """
  def delete_shop(%Shop{} = shop) do
    Repo.delete(shop)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shop changes.

  ## Examples

      iex> change_shop(shop)
      %Ecto.Changeset{data: %Shop{}}

  """
  def change_shop(%Shop{} = shop, attrs \\ %{}) do
    Shop.changeset(shop, attrs)
  end

  alias FileFinder.Files.File

  def sync_shop_files!(id) do
    shop = get_shop!(id) |> Repo.preload(:files)
    {:ok, shopify_ids} = File.request_shopify_ids(shop)

    deleted =
      shop.files
      |> Enum.reduce([], fn file, deleted ->
        if Enum.member?(shopify_ids, file.shopify_id) do
          deleted
        else
          [Repo.delete!(file) | deleted]
        end
      end)

    init_data = %{inserted: [], updated: [], deleted: deleted}

    shopify_ids
    |> Enum.reduce(init_data, fn shopify_id, data ->
      {:ok, changeset} = File.request_changeset(shopify_id, shop)

      cond do
        changeset.changes == %{} ->
          data

        changeset.data.id ->
          Map.merge(data, %{updated: data.updated ++ [Repo.update!(changeset)]})

        true ->
          Map.merge(data, %{inserted: data.inserted ++ [Repo.insert!(changeset)]})
      end
    end)
  end
end
