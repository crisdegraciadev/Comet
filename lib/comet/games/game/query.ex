defmodule Comet.Games.Game.Query do
  import Ecto.Query
  alias Comet.Repo
  alias Comet.Games.Game
  alias Comet.Accounts.User

  def all(), do: Repo.all(Game)

  def all(%User{id: user_id}, filter \\ %{}) do
    Game
    |> where([g], g.user_id == ^user_id)
    |> with_status(filter["status"])
    |> with_platform(filter["platform"])
    |> search_by(filter["name"])
    |> Repo.all()
  end

  defp with_status(query, status) when status in ~w(completed in_progress pending) do
    where(query, [g], g.status == ^String.to_existing_atom(status))
  end
  defp with_status(query, _), do: query

  defp search_by(query, value) when value in ["", nil], do: query
  defp search_by(query, value) do
    where(query, [g], ilike(g.name, ^"%#{value}%"))
  end

  defp with_platform(query, platform) when platform in ~w(pc ps1 ps2 ps3 ps4 ps5 psp switch) do
    where(query, [g], g.platform == ^String.to_existing_atom(platform))
  end
  defp with_platform(query, _), do: query

  def get!(%User{id: user_id}, id) when is_integer(id) do
    Game
    |> where([g], g.user_id == ^user_id)
    |> Repo.get!(id)
  end

  def get!(%User{} = user, id) when is_binary(id) do
    id |> String.to_integer() |> get!(user)
  end
end
