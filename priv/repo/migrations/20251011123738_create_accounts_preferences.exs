defmodule Comet.Repo.Migrations.CreateAccountsPreferences do
  use Ecto.Migration

  def change do
    create table(:accounts_preferences) do
      add :cols, :integer
      add :name, :boolean, default: true, null: false
      add :assets, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:accounts_preferences, [:user_id])
  end
end
