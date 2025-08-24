defmodule Comet.Repo.Migrations.AddGameHeroField do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :hero, :string
    end
  end
end
