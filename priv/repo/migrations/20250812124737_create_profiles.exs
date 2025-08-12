defmodule Comet.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :username, :string, null: true
      add :name, :string, null: true
      add :surname, :string, null: true
      add :api_key, :string, null: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])
    create unique_index(:profiles, [:username])
    create unique_index(:profiles, [:api_key])
  end
end
