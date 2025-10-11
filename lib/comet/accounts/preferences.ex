defmodule Comet.Accounts.Preferences do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts_preferences" do
    field :cols, :integer
    field :name, :boolean, default: false
    field :assets, Ecto.Enum, values: [:cover, :hero, :logo]
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preferences, attrs, user_scope) do
    preferences
    |> cast(attrs, [:cols, :name, :assets])
    |> validate_required([:cols, :name, :assets])
    |> put_change(:user_id, user_scope.user.id)
  end
end
