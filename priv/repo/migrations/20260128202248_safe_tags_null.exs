defmodule Comet.Repo.Migrations.SafeTagsNull do
  use Ecto.Migration

  def change do
    alter table(:games) do
      modify :status_id, :bigint, null: false
      modify :platform_id, :bigint, null: false
      modify :sgdb_id, :bigint
      modify :user_id, :bigint
    end
  end
end
