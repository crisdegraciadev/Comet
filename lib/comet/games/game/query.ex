defmodule Comet.Games.Game.Query do
  import Ecto.Query

  alias Comet.Repo
  alias Comet.Games.Game

  def all(), do: Game |> Repo.all()

  def all(filter) do
    Game
    |> with_status(filter["status"])
    |> with_platform(filter["platform"])
    |> search_by(filter["name"])
    |> Repo.all()
  end

  defp with_status(query, status) when status in ~w(completed in_progress pending) do
    where(query, status: ^status)
  end

  defp with_status(query, _), do: query

  defp search_by(query, value) when value in ["", nil], do: query

  defp search_by(query, value) do
    where(query, [g], ilike(g.name, ^"%#{value}%"))
  end

  defp with_platform(query, platform) when platform in ~w(pc ps1 ps2 ps3 ps4 ps5 psp switch) do
    where(query, platform: ^platform)
  end

  defp with_platform(query, _), do: query

  def get!(id) when is_integer(id) do
    Game |> Repo.get!(id)
  end

  def get!(id) when is_binary(id) do
    id |> String.to_integer() |> get!()
  end
end
