defmodule CometWeb.BacklogLive.Backlog do
  use CometWeb, :live_view

  alias Comet.Accounts
  alias Comet.Games
  alias Comet.Tags
  alias CometWeb.Layouts
  alias CometWeb.LiveComponents.ImageSelectorComponent

  import CometWeb.Live.BacklogLive.Components

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["backlog"]}
      full_width={true}
    >
      <div id="backlog-page" class="flex flex-col gap-4" phx-hook="PreserveScroll">
        <.filters user={@current_scope.user} />
        <.game_list streams={@streams} preferences={@preferences} />

        <.display_options_modal :if={@live_action == :display_options} preferences={@preferences} />
        <.show_game_modal :if={@live_action == :show} game={@game} />
        <.delete_game_modal :if={@live_action == :delete} game={@game} />
        <.edit_game_modal
          :if={@live_action == :edit}
          game={@game}
          user={@current_scope.user}
          platforms={@platforms}
          statuses={@statuses}
        />

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

    preferences = Accounts.get_account_preferences!(user)

    statuses = Tags.all_statuses(user)
    platforms = Tags.all_platforms(user)

    game_list = Games.all_games(user, %{"sort" => "status", "order" => "asc"})

    socket =
      socket
      |> assign(:current_scope, %{user: user})
      |> assign(:preferences, preferences)
      |> assign(:statuses, statuses)
      |> assign(:platforms, platforms)
      |> stream(:game_list, game_list)

    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _url,
        %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket
      )
      when live_action in [:show, :edit, :delete, :images_edit] do
    game = Games.get_game!(user, String.to_integer(id))

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", params, %{assigns: %{current_scope: %{user: user}}} = socket) do
    socket =
      socket
      |> assign(:form, to_form(params))
      |> stream(:game_list, Games.all_games(user, params), reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_display",
        params,
        %{assigns: %{preferences: preferences, current_scope: %{user: user}}} = socket
      ) do
    {:ok, updated_preferences} = Accounts.update_account_preferences(preferences, user, params)

    socket =
      socket
      |> assign(:preferences, updated_preferences)
      |> stream(:game_list, Games.all_games(user))

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    game = Games.get_game!(user, id)
    Games.delete_game!(game)

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
    {:ok, updated_game} = Games.update_game(game, user, game_params)

    game = Games.get_game!(user, updated_game.id)

    socket =
      socket
      |> assign(:game, game)
      |> stream_insert(:game_list, game)
      |> put_flash(:info, "Game updated!")
      |> push_patch(to: ~p"/backlog/#{updated_game.id}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_image, updated_game}, socket) do
    {:noreply, socket |> stream_insert(:game_list, updated_game)}
  end
end
