defmodule FileFinder.Repo.Migrations.CreateShops do
  use Ecto.Migration

  def change do
    create table(:shops) do
      add :name, :string
      add :token, :string

      timestamps()
    end

    create unique_index(:shops, [:name])
  end
end
