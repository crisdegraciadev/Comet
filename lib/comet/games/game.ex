defmodule Comet.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :cover, :string
    field :status, Ecto.Enum, values: [:completed, :in_progress, :pending], default: :pending

    field :platform, Ecto.Enum,
      values: [
        :pc,
        :ps1,
        :ps2,
        :ps3,
        :ps4,
        :ps5,
        :xbox_360,
        :xbox_one,
        :switch,
        :switch2,
        :n64,
        :ds,
        :psp
      ]

    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs, user_scope) do
    game
    |> cast(attrs, [:name, :cover, :status, :platform])
    |> validate_required([:name, :cover, :status, :platform])
    |> put_change(:user_id, user_scope.user.id)
  end
end
