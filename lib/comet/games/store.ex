defmodule Comet.Games.Store do
  alias Comet.Accounts
  alias Comet.Games.Game
  alias Comet.Repo

  def change_game(%Game{} = game, %Accounts.User{} = user, attrs \\ %{}) do
    Game.changeset(game, attrs, %{user: user})
  end

  def delete_game!(%Game{} = game) do
    Repo.delete!(game)
  end

  def update_game(%Game{} = game, %Accounts.User{} = user, attrs) do
    game |> change_game(user, attrs) |> Repo.update()
  end

  def create_game(%Accounts.User{} = user, attrs) do
    %Game{} |> change_game(user, attrs) |> Repo.insert()
  end
end
