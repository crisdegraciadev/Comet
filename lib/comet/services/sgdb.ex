defmodule Comet.Services.SGDB do
  @moduledoc """
  Service for interacting with the SteamGridDB API.
  Documentation: https://www.steamgriddb.com/api/v2
  """

  @base_url "https://www.steamgriddb.com/api/v2"

  def search(query, _) when byte_size(query) == 0, do: {:error, "Empty query"}

  def search(query, api_key) do
    case Req.get(search_url(query), options(api_key)) do
      {:ok, %{body: %{"data" => data}}} -> {:ok, parse_games(data)}
      {:error, reason} -> {:error, reason}
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

  defp search_url(query), do: "#{@base_url}/search/autocomplete/#{URI.encode(query)}"
  defp game_url(id), do: "#{@base_url}/games/id/#{id}"
  defp cover_url(id), do: "#{@base_url}/grids/game/#{id}?dimensions=600x900"
  defp hero_url(id), do: "#{@base_url}/heroes/game/#{id}?dimensions=1920x620"

  defp parse_game(data),
    do: %{id: data["id"], name: data["name"]}

  defp parse_games(data),
    do: Enum.map(data, fn game -> parse_game(game) end)

  defp parse_covers(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)

  defp parse_heroes(data),
    do: Enum.map(data, fn cover -> %{style: cover["style"], url: cover["url"]} end)
end
