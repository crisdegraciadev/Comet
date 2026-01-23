defmodule Comet.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :sgdb_id, :integer
    field :cover, :string
    field :hero, :string

    belongs_to :user, Comet.Accounts.User
    belongs_to :status, Comet.Tags.Status
    belongs_to :platform, Comet.Tags.Platform

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs, user_scope) do
    game
    |> cast(attrs, [:name, :sgdb_id, :status_id, :platform_id, :cover, :hero])
    |> validate_required([:status_id, :platform_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
