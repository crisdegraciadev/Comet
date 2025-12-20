defmodule Comet.Repo.Migrations.ChangePreferencesNameToShowName do
  use Ecto.Migration

  def change do
    rename table(:accounts_preferences), :name, to: :show_name
  end
end
