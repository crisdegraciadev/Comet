defmodule CometWeb.Live.BrowserLive.Helpers do
  use CometWeb, :live_view

  alias Comet.Games.Game
  alias Comet.Services.SGDB

  def assign_game(%{assigns: %{api_key: api_key}} = socket, id) do
    {:ok, %{game: %{id: id, name: name}}} = SGDB.get_game(id, api_key)
    {:ok, %{covers: covers}} = SGDB.get_covers(id, api_key)
    {:ok, %{heroes: heroes}} = SGDB.get_heroes(id, api_key)

    sgdb_game = %{
      id: id,
      name: name,
      cover: Game.Utils.main_asset_url(covers),
      hero: Game.Utils.main_asset_url(heroes)
    }

    assign(socket, :sgdb_game, sgdb_game)
  end

  def assign_results(%{assigns: %{query: query}} = socket) do
    case SGDB.search(query) do
      {:ok, results} -> socket |> assign(:results, results)
      {:error, reason} -> socket |> put_flash(:error, reason)
    end
  end

  def assign_api_key(socket) do
    user = Comet.Accounts.get_user_with_profile!(socket.assigns.current_scope.user.id)
    api_key = user.profile.api_key

    assign(socket, %{
      api_key: api_key,
      current_scope: %{user: user}
    })
  end
end
