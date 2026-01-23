defmodule Comet.Repo.Migrations.RemoveGameEnums do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :status
      remove :platform
    end
  end
end
