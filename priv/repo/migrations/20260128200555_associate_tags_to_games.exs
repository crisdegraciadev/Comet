defmodule Comet.Repo.Migrations.AssociateTagsToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :platform_id, references(:platforms)
      add :status_id, references(:statuses)
    end

    create index(:games, [:platform_id])
    create index(:games, [:status_id])
  end
end
