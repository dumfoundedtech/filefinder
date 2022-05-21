defmodule FileFinder.Files.Dir do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dirs" do
    field :name, :string
    field :dir_id, :id
    field :shop_id, :id

    timestamps()
  end

  @doc false
  def changeset(dir, attrs) do
    dir
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
