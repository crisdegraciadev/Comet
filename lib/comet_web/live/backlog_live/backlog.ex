defmodule CometWeb.BacklogLive.Backlog do
  use CometWeb, :live_view

  alias Comet.Accounts.Preferences
  alias Comet.Games.Game
  alias CometWeb.LiveComponents.ImageSelectorComponent

  import CometWeb.Live.BacklogLive.Components

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["backlog", "collection"]}
    >
      <div id="backlog-page" class="flex flex-col gap-4" phx-hook="PreserveScroll">
        <.in_progress_game_list streams={@streams} preferences={@preferences} />
        <.filters />
        <.game_list streams={@streams} preferences={@preferences} />

        <.show_game_modal :if={@live_action == :show} game={@game} />
        <.delete_game_modal :if={@live_action == :delete} game={@game} />
        <.edit_game_modal :if={@live_action == :edit} game={@game} current_scope={@current_scope} />
        <.display_options_modal :if={@live_action == :display_options} preferences={@preferences} />

        <.live_component
          :if={@live_action == :images_edit}
          module={ImageSelectorComponent}
          id={"images-selector-#{@game.id}"}
          game={@game}
          current_scope={@current_scope}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    user = Comet.Repo.preload(user, :profile)
    preferences = Preferences.Query.get!(user)

    socket =
      socket
      |> assign(:current_scope, %{user: user})
      |> assign(:preferences, preferences)
      |> stream(:game_list, Game.Query.all(user, %{"sort" => "status", "order" => "asc"}))
      |> stream(:in_progress_game_list, Game.Query.all(user, %{"status" => "in_progress"}))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:list, :display_options] do
    {:noreply, assign(socket, :game, nil)}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _url,
        %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket
      )
      when live_action in [:show, :edit, :delete, :images_edit] do
    game = Game.Query.get!(user, String.to_integer(id))

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("filter", params, %{assigns: %{current_scope: %{user: user}}} = socket) do
    socket =
      socket
      |> assign(:form, to_form(params))
      |> stream(:game_list, Game.Query.all(user, params), reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_display",
        params,
        %{assigns: %{preferences: preferences, current_scope: %{user: user}}} = socket
      ) do
    {:ok, updated_preferences} = Preferences.Command.update(preferences, user, params)

    socket =
      socket
      |> assign(:preferences, updated_preferences)
      |> stream(:game_list, Game.Query.all(user))
      |> stream(:in_progress_game_list, Game.Query.all(user, %{"status" => "in_progress"}))

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    game = Game.Query.get!(user, id)
    Game.Command.delete!(game)

    socket =
      socket
      |> stream_delete(:game_list, game)
      |> put_flash(:info, "Game deleted")
      |> push_patch(to: ~p"/backlog", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "update",
        %{"game" => game_params},
        %{assigns: %{game: game, current_scope: %{user: user}}} = socket
      ) do
    {:ok, updated_game} = Game.Command.update(game, user, game_params)

    socket =
      socket
      |> assign(:game, updated_game)
      |> stream_insert(:game_list, updated_game)
      |> stream(:in_progress_game_list, Game.Query.all(user, %{"status" => "in_progress"}),
        reset: true
      )
      |> put_flash(:info, "Game updated!")
      |> push_patch(to: ~p"/backlog/#{updated_game.id}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_image, updated_game}, socket) do
    {:noreply, socket |> stream_insert(:game_list, updated_game)}
  end
end
