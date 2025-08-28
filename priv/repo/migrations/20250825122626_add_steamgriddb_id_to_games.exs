defmodule Comet.Repo.Migrations.AddSteamgriddbIdToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :steamgriddb_id, :integer
    end
  end
end
