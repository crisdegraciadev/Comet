defmodule Comet.Repo.Migrations.RemoveValueColFromTags do
  use Ecto.Migration

  def change do
    alter table(:platforms), do: remove(:value)
    alter table(:statuses), do: remove(:value)
  end
end
