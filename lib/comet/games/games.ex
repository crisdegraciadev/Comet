defmodule Comet.Games do
  alias Comet.Games.Queries
  alias Comet.Games.SGDB
  alias Comet.Games.Store

  defdelegate all_games(user, filter \\ %{}), to: Queries
  defdelegate random_games(limit), to: Queries
  defdelegate get_game!(user, id), to: Queries
  defdelegate count_games_by_platform(user), to: Queries
  defdelegate count_games_by_status(user), to: Queries

  defdelegate search_sgdb_games(term), to: SGDB
  defdelegate get_sgdb_game(id, api_key), to: SGDB
  defdelegate get_sgdb_covers(id, api_key), to: SGDB
  defdelegate get_sgdb_heroes(id, api_key), to: SGDB

  defdelegate change_game(game, user, attrs \\ %{}), to: Store
  defdelegate delete_game!(game), to: Store
  defdelegate update_game(game, user, attrs), to: Store
  defdelegate create_game(user, attrs), to: Store
end
