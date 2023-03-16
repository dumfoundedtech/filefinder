defmodule FileFinder.Repo.Migrations.CreateShops do
  use Ecto.Migration

  def change do
    create table(:shops) do
      add :name, :string, null: false
      add :token, :string, null: false
      add :active, :boolean, null: false, default: true

      timestamps()
    end

    create unique_index(:shops, [:name])
  end
end
