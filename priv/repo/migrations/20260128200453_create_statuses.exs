defmodule Comet.Repo.Migrations.CreateStatuses do
  use Ecto.Migration

  def change do
    create table(:statuses) do
      add :value, :string
      add :label, :string
      add :foreground, :string
      add :background, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:statuses, [:user_id])
  end
end
