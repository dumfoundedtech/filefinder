defmodule FileFinder.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :shopify_id, :string, null: false
      add :url, :string, null: false
      add :type, :string, null: false
      add :alt, :string, null: false
      add :preview_url, :string, null: false
      add :shopify_timestamp, :utc_datetime, null: false
      add :dir_id, references(:dirs, on_delete: :delete_all)
      add :shop_id, references(:shops, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:files, [:url])
    create unique_index(:files, [:shopify_id])
    create index(:files, [:dir_id])
    create index(:files, [:shop_id])
  end
end
