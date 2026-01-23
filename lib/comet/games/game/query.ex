defmodule Comet.Games.Game.Query do
  import Ecto.Query

  alias Comet.Accounts.User
  alias Comet.Games.Game
  alias Comet.Repo

  def all(%User{id: user_id}, filter \\ %{}) do
    Game
    |> for_user(user_id)
    |> with_status(filter["status"])
    |> with_platform(filter["platform"])
    |> search_by(filter["name"])
    |> with_order(filter["sort"], filter["order"])
    |> preload_static_data()
    |> Repo.all()
  end

  def random(limit \\ 1) do
    Game
    |> order_by(fragment("RANDOM()"))
    |> limit(^limit)
    |> Repo.all()
  end

  defp for_user(query, user_id) do
    where(query, [g], g.user_id == ^user_id)
  end

  defp with_platform(query, platform_id) when platform_id != nil do
    where(query, [g], g.platform == ^platform_id)
  end

  defp with_platform(query, _), do: query

  defp with_status(query, status_id) when status_id != nil do
    where(query, [g], g.status_id == ^status_id)
  end

  defp with_status(query, _), do: query

  defp search_by(query, value) when value in ["", nil], do: query

  defp search_by(query, value) do
    where(query, [g], ilike(g.name, ^"%#{value}%"))
  end

  defp with_order(query, sort, order) when order in ~w(asc desc) do
    direction = String.to_atom(order)

    case sort do
      "title" ->
        order_by(query, [g], [{^direction, g.name}])

      "status" ->
        query
        |> join(:left, [g], s in assoc(g, :status))
        |> order_by([g, s], [{^direction, s.label}])

      "platform" ->
        query
        |> join(:left, [g], p in assoc(g, :platform))
        |> order_by([g, p], [{^direction, p.label}])

      _ ->
        query
    end
  end

  defp with_order(query, _, _), do: query

  defp preload_static_data(query), do: preload(query, [:status, :platform])

  def get!(%User{id: user_id}, id) when is_integer(id) do
    Game
    |> for_user(user_id)
    |> Repo.get!(id)
  end

  def get!(%User{} = user, id) when is_binary(id), do: get!(user, String.to_integer(id))
end
