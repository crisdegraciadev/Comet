defmodule Comet.Repo.Migrations.RenameSteamdbgridIdToSgdbId do
  use Ecto.Migration

  def change do
    rename table(:games), :steamgriddb_id, to: :sgdb_id
  end
end
