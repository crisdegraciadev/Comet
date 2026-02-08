defmodule Comet.Tags.Status do
  use Ecto.Schema
  import Ecto.Changeset

  schema "statuses" do
    field :label, :string
    field :foreground, :string
    field :background, :string

    has_many :games, Comet.Games.Game

    belongs_to :user, Comet.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(status, attrs, user_scope) do
    status
    |> cast(attrs, [:label, :foreground, :background])
    |> validate_required([:label, :foreground, :background])
    |> unique_constraint(:label, message: "Status with this label already exists.")
    |> foreign_key_constraint(:base,
      name: "games_status_id_fkey",
      message: "Status is used in some games."
    )
    |> put_change(:user_id, user_scope.user.id)
  end
end
