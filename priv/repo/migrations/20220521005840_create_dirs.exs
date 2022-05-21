defmodule FileFinder.Repo.Migrations.CreateDirs do
  use Ecto.Migration

  def change do
    create table(:dirs) do
      add :name, :string
      add :dir_id, references(:dirs, on_delete: :delete_all)
      add :shop_id, references(:shops, on_delete: :delete_all)

      timestamps()
    end

    create index(:dirs, [:dir_id])
    create index(:dirs, [:shop_id])
  end
end
