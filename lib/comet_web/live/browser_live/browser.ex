defmodule CometWeb.BrowserLive.Browser do
  use CometWeb, :live_view

  alias Comet.Games.Game
  alias Comet.Games.Game.SGDB
  alias CometWeb.Utils

  import CometWeb.Live.BrowserLive.Components

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["browser"]}
    >
      <.search_form api_key={@api_key} query={assigns[:query]} />
      <.search_results
        :if={@api_key}
        api_key={@api_key}
        results={assigns[:results]}
        query={assigns[:query]}
      />

      <.add_game_modal
        :if={@live_action == :new}
        sgdb_game={@sgdb_game}
        user={@current_scope.user}
        query={@query}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"query" => query, "id" => id}, _session, socket) do
    socket =
      socket
      |> assign(:query, query)
      |> assign_api_key()
      |> assign_game(id)
      |> assign_results()

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"query" => query}, _session, socket) do
    socket = socket |> assign(:query, query) |> assign_api_key() |> assign_results()

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    socket = socket |> assign_api_key()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/browser?query=#{query}", replace: true)}
  end

  @impl true
  def handle_event("save", %{"game" => game_params}, socket) do
    user = socket.assigns.current_scope.user
    query = socket.assigns.query

    case Game.Command.create(user, game_params) do
      {:ok, game} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{game.name} added to backlog")
         |> push_navigate(to: ~p"/browser?query=#{query}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error adding game to backlog")}
    end
  end

  defp assign_game(%{assigns: %{api_key: api_key}} = socket, id) do
    {:ok, %{game: %{id: id, name: name}}} = SGDB.get_game(id, api_key)
    {:ok, %{covers: covers}} = SGDB.get_covers(id, api_key)
    {:ok, %{heroes: heroes}} = SGDB.get_heroes(id, api_key)

    sgdb_game = %{
      id: id,
      name: name,
      cover: Utils.Assets.main_asset_url(covers),
      hero: Utils.Assets.main_asset_url(heroes)
    }

    assign(socket, :sgdb_game, sgdb_game)
  end

  defp assign_results(%{assigns: %{query: query}} = socket) do
    case SGDB.search(query) do
      {:ok, results} -> socket |> assign(:results, results)
      {:error, reason} -> socket |> put_flash(:error, reason)
    end
  end

  defp assign_api_key(socket) do
    user = Comet.Accounts.get_user_with_profile!(socket.assigns.current_scope.user.id)
    api_key = user.profile.api_key

    assign(socket, %{
      api_key: api_key,
      current_scope: %{user: user}
    })
  end
end
