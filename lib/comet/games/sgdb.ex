defmodule Comet.Games.SGDB do
  @moduledoc """
  Service for interacting with the SteamGridDB API.
  Documentation: https://www.steamgriddb.com/api/v2
  """

  alias Comet.Cache

  @api_v2 "https://www.steamgriddb.com/api/v2"
  @public_api "https://www.steamgriddb.com/api/public"

  def search_sgdb_games(term) when byte_size(term) == 0, do: {:error, "Empty search term"}

  def search_sgdb_games(term) do
    case Cache.get(search_key(term)) do
      nil -> sgdb_search(term)
      value -> {:ok, value}
    end
  end

  defp sgdb_search(term) do
    base_json = %{
      asset_type: "grid",
      term: term,
      filters: %{order: "score_desc", dimensions: "600x900"}
    }

    results =
      Enum.map(0..3, fn offset ->
        case Req.post(search_url(), json: Map.put(base_json, :offset, offset)) do
          {:ok, %{body: %{"data" => %{"games" => games}}}} -> parse_games(games)
          {:error, reason} -> {:error, reason}
        end
      end)

    ordered_results =
      case Enum.find(results, &match?({:error, _}, &1)) do
        {:error, reason} ->
          {:error, reason}

        _ ->
          {:ok,
           results
           |> Enum.concat()
           |> Enum.sort_by(& &1.score, :desc)
           |> tap(fn ordered_results -> Cache.put(search_key(term), ordered_results) end)}
      end

    ordered_results
  end

  def get_sgdb_game(id, api_key) do
    case Cache.get(game_key(id)) do
      nil -> fetch(game_key(id), game_url(id), :game, api_key, &parse_game/1)
      value -> {:ok, %{game: value}}
    end
  end

  def get_sgdb_covers(id, api_key) do
    case Cache.get(covers_key(id)) do
      nil -> fetch(covers_key(id), cover_url(id), :covers, api_key, &parse_covers/1)
      value -> {:ok, %{covers: value}}
    end
  end

  def get_sgdb_heroes(id, api_key) do
    case Cache.get(heroes_key(id)) do
      nil -> fetch(heroes_key(id), hero_url(id), :heroes, api_key, &parse_heroes/1)
      value -> {:ok, %{heroes: value}}
    end
  end

  defp fetch(key, url, resp_key, api_key, parser) do
    with {:ok, %{body: %{"data" => data}}} <- Req.get(url, options(api_key)),
         parsed <- parser.(data) do
      Cache.put(key, parsed)
      {:ok, Map.put(%{}, resp_key, parsed)}
    else
      {:ok, %{body: %{"data" => []}}} -> {:error, "No data found"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp options(api_key) do
    [headers: auth_headers(api_key), receive_timeout: 5_000]
  end

  defp auth_headers(api_key),
    do: [{"Authorization", "Bearer #{api_key}"}, {"Accept", "application/json"}]

  defp search_url(), do: "#{@public_api}/search/main/games"
  defp game_url(id), do: "#{@api_v2}/games/id/#{id}"
  defp cover_url(id), do: "#{@api_v2}/grids/game/#{id}?dimensions=600x900"
  defp hero_url(id), do: "#{@api_v2}/heroes/game/#{id}?dimensions=1920x620"

  defp search_key(term), do: "search_#{term}"
  defp game_key(id), do: "game_#{id}"
  defp covers_key(id), do: "covers_#{id}"
  defp heroes_key(id), do: "heroes_#{id}"

  defp parse_game(game, meta \\ %{"total" => 0}),
    do: %{id: game["id"], name: game["name"], score: meta["total"]}

  defp parse_games(data),
    do: Enum.map(data, fn %{"game" => game, "meta" => meta} -> parse_game(game, meta) end)

  defp parse_covers(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)

  defp parse_heroes(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)
end
