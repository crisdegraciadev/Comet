defmodule CometWeb.BrowserLive.Browser do
  use CometWeb, :live_view

  alias Comet.Games.Game

  import CometWeb.Live.BrowserLive.Components
  import CometWeb.Live.BrowserLive.Helpers

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["browser", "collection"]}
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
        current_scope={@current_scope}
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
end
