defmodule Comet.Accounts.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :username, :string
    field :name, :string
    field :surname, :string
    field :api_key, :string

    belongs_to :user, Comet.Accounts.User

    timestamps(type: :utc_datetime)

  end

  @doc false
  def changeset(profile, attrs, user_scope, opts \\ []) do
    profile
    |> cast(attrs, [:username, :name, :surname, :api_key])
    |> unique_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end
end
