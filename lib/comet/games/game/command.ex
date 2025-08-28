defmodule Comet.Games.Game.Command do
  alias Comet.Repo
  alias Comet.Games.Game
  alias Comet.Accounts.User

  def change(%Game{} = game, %User{} = user, attrs \\ %{}) do
    Game.changeset(game, attrs, %{user: user})
  end

  def delete!(%Game{} = game) do
    Repo.delete!(game)
  end

  def update(%Game{} = game, %User{} = user, attrs) do
    game |> change(user, attrs) |> Repo.update()
  end

  def create(%User{} = user, attrs) do
    %Game{} |> change(user, attrs) |> Repo.insert()
  end
end
