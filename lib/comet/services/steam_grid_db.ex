defmodule Comet.Services.SteamGridDB do
  @moduledoc """
  Service for interacting with the SteamGridDB API.
  Documentation: https://www.steamgriddb.com/api/v2
  """

  @base_url "https://www.steamgriddb.com/api/v2"
  @portrait_dimension "600x900"

  defp auth_headers(api_key),
    do: [{"Authorization", "Bearer #{api_key}"}, {"Accept", "application/json"}]

  def search_games(query, api_key) when is_binary(query) and byte_size(query) > 0 do
    case api_key do
      nil -> {:error, "API key not configured"}
      "" -> {:error, "API key not configured"}
      key -> do_search_games(query, key)
    end
  end

  def search_games(_query, _api_key), do: {:error, "Invalid query"}

  def search_games_with_covers(query, api_key) when is_binary(query) and byte_size(query) > 0 do
    with {:ok, games} <- search_games(query, api_key) do
      games_with_covers =
        games
        |> Task.async_stream(
          fn game ->
            cover_url = get_cover_url(game.id, api_key)
            Map.put(game, :cover_url, cover_url)
          end,
          max_concurrency: 5,
          timeout: 5_000
        )
        |> Enum.map(fn {:ok, game} -> game end)

      {:ok, games_with_covers}
    end
  end

  defp do_search_games(query, api_key) do
    url = "#{@base_url}/search/autocomplete/#{URI.encode(query)}"
    alternative_url = "#{@base_url}/games/search?q=#{URI.encode(query)}"

    with {:ok, %Req.Response{status: 200, body: %{"data" => games}}} <- Req.get(url, headers: auth_headers(api_key), receive_timeout: 5_000) do
      if is_list(games) do
        {:ok, Enum.map(games, &parse_game/1)}
      else
        {:ok, []}
      end
    else
      {:ok, %Req.Response{status: 401}} -> {:error, "Invalid API key"}
      {:ok, %Req.Response{status: _}} ->
        case Req.get(alternative_url, headers: auth_headers(api_key), receive_timeout: 5_000) do
          {:ok, %Req.Response{status: 200, body: %{"data" => games}}} when is_list(games) ->
            {:ok, Enum.map(games, &parse_game/1)}
          _ ->
            {:ok, []}
        end
      {:error, error} -> {:error, "Network error: #{inspect(error)}"}
    end
  end

  def get_cover_url(game_id, api_key) when is_integer(game_id) do
    url = "#{@base_url}/grids/game/#{game_id}?dimensions=#{@portrait_dimension}"

    case Req.get(url, headers: auth_headers(api_key), receive_timeout: 5_000) do
      {:ok, %Req.Response{status: 200, body: %{"data" => grids}}} when is_list(grids) and length(grids) > 0 ->
        chosen = Enum.find(grids, &(&1["style"] == "official")) || List.first(grids)
        Map.get(chosen, "url", get_fallback_cover_url(game_id))
      _ ->
        get_fallback_cover_url(game_id)
    end
  end

  defp get_fallback_cover_url(game_id) do
    "https://via.placeholder.com/600x900/666666/FFFFFF?text=Game+#{game_id}"
  end

  defp parse_game(%{"id" => id, "name" => name} = game) do
    %{
      id: id,
      name: name,
      verified: Map.get(game, "verified", false),
      types: Map.get(game, "types", []),
      steam_id: Map.get(game, "steam_appid"),
      release_date: Map.get(game, "release_date")
    }
  end

  def get_hero(game_id, api_key) when is_integer(game_id) do
    url = "#{@base_url}/heroes/game/#{game_id}?dimensions=1920x620"

    case Req.get(url, headers: auth_headers(api_key), receive_timeout: 5_000) do
      {:ok, %Req.Response{status: 200, body: %{"data" => heroes}}} when is_list(heroes) and length(heroes) > 0 ->
        chosen = List.first(heroes)
        Map.get(chosen, "url", get_fallback_hero_url(game_id))
      _ ->
        get_fallback_hero_url(game_id)
    end
  end

  defp get_fallback_hero_url(game_id) do
    "https://via.placeholder.com/1920x800/666666/FFFFFF?text=Game+#{game_id}"
  end

  def get_all_covers(game_id, api_key) when is_integer(game_id) do
    url = "#{@base_url}/grids/game/#{game_id}?dimensions=#{@portrait_dimension}"

    case Req.get(url, headers: auth_headers(api_key), receive_timeout: 5_000) do
      {:ok, %Req.Response{status: 200, body: %{"data" => grids}}} when is_list(grids) and length(grids) > 0 ->
        grids
        |> Enum.map(&Map.get(&1, "url", get_fallback_cover_url(game_id)))
        |> Enum.filter(& &1)
        |> Enum.uniq()

      _ ->
        [get_fallback_cover_url(game_id)]
    end
  end

  def get_all_heroes(game_id, api_key) when is_integer(game_id) do
    url = "#{@base_url}/heroes/game/#{game_id}?dimensions=1920x620"

    case Req.get(url, headers: auth_headers(api_key), receive_timeout: 5_000) do
      {:ok, %Req.Response{status: 200, body: %{"data" => heroes}}} when is_list(heroes) and length(heroes) > 0 ->
        heroes
        |> Enum.map(&Map.get(&1, "url", get_fallback_hero_url(game_id)))
        |> Enum.filter(& &1)
        |> Enum.uniq()

      _ ->
        [get_fallback_hero_url(game_id)]
    end
  end
end
