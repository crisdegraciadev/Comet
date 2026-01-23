defmodule Comet.Tags.Platform do
  use Ecto.Schema
  import Ecto.Changeset

  schema "platforms" do
    field :label, :string
    field :foreground, :string
    field :background, :string

    has_many :games, Comet.Games.Game

    belongs_to :user, Comet.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(platform, attrs, user_scope) do
    platform
    |> cast(attrs, [:label, :foreground, :background])
    |> validate_required([:label, :foreground, :background])
    |> unique_constraint(:label, message: "Platform with this label already exists.")
    |> foreign_key_constraint(:base, name: "games_platform_id_fkey", message: "Platform is used in some games.")
    |> put_change(:user_id, user_scope.user.id)
  end
end
