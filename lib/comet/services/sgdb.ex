defmodule Comet.Services.SGDB do
  @moduledoc """
  Service for interacting with the SteamGridDB API.
  Documentation: https://www.steamgriddb.com/api/v2
  """

  @api_v2 "https://www.steamgriddb.com/api/v2"
  @public_api "https://www.steamgriddb.com/api/public"

  def search(term, _) when byte_size(term) == 0, do: {:error, "Empty search term"}

  def search(term) do
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

    case Enum.find(results, &match?({:error, _}, &1)) do
      {:error, reason} -> {:error, reason}
      _ -> {:ok, results |> Enum.concat() |> Enum.sort_by(& &1.score, :desc)}
    end
  end

  def get_game(id, api_key) do
    case Req.get(game_url(id), options(api_key)) do
      {:ok, %{body: %{"data" => []}}} -> {:error, "No game found"}
      {:ok, %{body: %{"data" => data}}} -> {:ok, %{game: parse_game(data)}}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_covers(id, api_key) do
    case Req.get(cover_url(id), options(api_key)) do
      {:ok, %{body: %{"data" => data}}} -> {:ok, %{covers: parse_covers(data)}}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_heroes(id, api_key) do
    case Req.get(hero_url(id), options(api_key)) do
      {:ok, %{body: %{"data" => data}}} -> {:ok, %{heroes: parse_heroes(data)}}
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

  defp parse_game(game, meta \\ %{"total" => 0}),
    do: %{id: game["id"], name: game["name"], score: meta["total"]}

  defp parse_games(data),
    do: Enum.map(data, fn %{"game" => game, "meta" => meta} -> parse_game(game, meta) end)

  defp parse_covers(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)

  defp parse_heroes(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)
end
