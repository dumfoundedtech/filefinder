defmodule FileFinder.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :alt, :string
    field :preview_url, :string
    field :shopify_id, :string
    field :shopify_timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:file, :image, :video]
    field :url, :string
    belongs_to :dir, FileFinder.Files.Dir
    belongs_to :shop, FileFinder.Shops.Shop

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :shopify_id,
      :url,
      :type,
      :alt,
      :preview_url,
      :shopify_timestamp,
      :dir_id,
      :shop_id
    ])
    |> validate_required([
      :shopify_id,
      :url,
      :type,
      :alt,
      :preview_url,
      :shopify_timestamp,
      :shop_id
    ])
    |> unique_constraint(:shopify_id)
    |> unique_constraint(:url)
  end
end
