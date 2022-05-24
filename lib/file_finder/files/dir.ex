defmodule FileFinder.Files.Dir do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dirs" do
    field :name, :string
    belongs_to :dir, FileFinder.Files.Dir
    belongs_to :shop, FileFinder.Shops.Shop
    has_many :files, FileFinder.Files.File

    timestamps()
  end

  @doc false
  def changeset(dir, attrs) do
    dir
    |> cast(attrs, [:name, :dir_id, :shop_id])
    |> validate_required([:name, :shop_id])
  end
end
