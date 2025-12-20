defmodule Comet.Accounts.Preferences do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts_preferences" do
    field :cols, :integer
    field :show_name, :boolean, default: false
    field :assets, Ecto.Enum, values: [:cover, :hero, :logo]
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preferences, attrs, user_scope) do
    preferences
    |> cast(attrs, [:cols, :show_name, :assets])
    |> validate_required([:cols, :show_name, :assets])
    |> put_change(:user_id, user_scope.user.id)
  end
end
