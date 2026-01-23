defmodule Comet.Repo.Migrations.AddUniqueConstraintToTags do
  use Ecto.Migration

  def change do
    create unique_index(:platforms, [:label])
    create unique_index(:statuses, [:label])
  end
end
