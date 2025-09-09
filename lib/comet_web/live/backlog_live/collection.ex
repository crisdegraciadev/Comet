defmodule CometWeb.BacklogLive.Collection do
  use CometWeb, :live_view
  alias Comet.Games
  alias Comet.Games.Game
  alias CometWeb.LiveComponents.ImageSelectorComponent

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["backlog", "collection"]}
    >
      <.filters />
      <.game_list streams={@streams} />

      <.show_game_modal :if={@live_action == :show} live_action={@live_action} game={@game} />
      <.delete_game_modal :if={@live_action == :delete} game={@game} />
      <.edit_game_modal :if={@live_action == :edit} game={@game} current_scope={@current_scope} />

      <.live_component
        :if={@live_action == :images_edit}
        module={ImageSelectorComponent}
        id={"images-selector-#{@game.id}"}
        game={@game}
        current_scope={@current_scope}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(
        %{"id" => id},
        _session,
        %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket
      )
      when live_action != :list do
    user = Comet.Repo.preload(user, :profile)
    game = Game.Query.get!(user, String.to_integer(id))

    socket =
      socket
      |> stream(:game_list, Game.Query.all(user))
      |> assign(:current_scope, %{user: user})
      |> assign(:game, game)

    {:ok, socket}
  end

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{live_action: :list, current_scope: %{user: user}}} = socket
      ) do
    user = Comet.Repo.preload(user, :profile)

    socket =
      socket
      |> stream(:game_list, Game.Query.all(user))
      |> assign(:current_scope, %{user: user})

    {:ok, socket}
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
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    game = Game.Query.get!(user, id)
    Game.Command.delete!(game)

    socket =
      socket
      |> stream_delete(:game_list, game)
      |> put_flash(:info, "Game deleted")
      |> push_navigate(to: ~p"/backlog/collection", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "update",
        %{"game" => game_params},
        %{assigns: %{game: game, current_scope: current_scope}} = socket
      ) do
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, game_params)

    socket =
      socket
      |> assign(:game, updated_game)
      |> put_flash(:info, "Game updated!")
      |> push_navigate(to: ~p"/backlog/collection/#{updated_game.id}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_status",
        %{"status" => status},
        %{assigns: %{game: game, current_scope: current_scope}} = socket
      ) do
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, %{status: status})

    socket =
      socket
      |> assign(:game, updated_game)
      |> stream_insert(:game_list, updated_game)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_image, updated_game}, socket) do
    {:noreply, socket |> stream_insert(:game_list, updated_game)}
  end

  defp filters(assigns) do
    form = to_form(%{"name" => "", "platform" => "", "status" => ""})
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()
    assigns = assign(assigns, %{form: form, platforms: platforms, statuses: statuses})

    ~H"""
    <.form class="flex gap-2" id="filter-form" phx-change="filter" for={@form}>
      <.input
        field={@form[:platform]}
        fieldset_class="w-1/8"
        type="select"
        options={@platforms}
        prompt="Platform"
      />
      <.input
        field={@form[:status]}
        fieldset_class="w-1/8"
        type="select"
        options={@statuses}
        prompt="Status"
      />
      <.input field={@form[:name]} fieldset_class="grow" placeholder="Search" autocomplete="off" />
    </.form>
    """
  end

  attr :streams, :any, required: true

  defp game_list(assigns) do
    ~H"""
    <div class="grid grid-cols-8 gap-4" id="games" phx-update="stream">
      <.game_card :for={{dom_id, game} <- @streams.game_list} id={dom_id} game={game} />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :game, Games.Game

  defp game_card(assigns) do
    ~H"""
    <.link id={@id} href={~p"/backlog/collection/#{@game}"}>
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-base-300 relative">
        <div class="absolute top-2 left-2 flex gap-1 flex-col">
          <.status_badge status={@game.status} />
          <.platform_badge platform={@game.platform} />
        </div>
        <img class="aspect-2/3 rounded-tl-md rounded-tr-md" src={@game.cover} />
        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@game.name}</span>
      </div>
    </.link>
    """
  end

  attr :live_action, :atom, required: true
  attr :game, Games.Game

  defp show_game_modal(assigns) do
    ~H"""
    <.game_modal id={"show-game-modal-#{@game.id}"} game={@game}>
      <:actions>
        <.button href={~p"/backlog/collection/#{@game}/edit"}>
          <.icon name="hero-pencil" /> Edit
        </.button>
        <.button variant="error" href={~p"/backlog/collection/#{@game}/delete"}>
          <.icon name="hero-trash" /> Delete
        </.button>
      </:actions>

      <div class="flex flex-col gap-2 rounded-box border border-base-content/10 bg-base-200  p-4">
        <div class="grid grid-cols-2">
          <span><.icon name="hero-circle-stack" class="mr-2 size-4" /> Status</span>
          <.status_badge status={@game.status} />
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="hero-computer-desktop" class="mr-2 size-4" />Platform</span>
          <.platform_badge platform={@game.platform} />
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="hero-calendar" class="mr-2 size-4" />Purchased</span>
          <span>15 de Enero, 2018</span>
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="hero-calendar-days" class="mr-2 size-4" />Completition</span>
          <span>10 de Junio, 2020</span>
        </div>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game

  defp delete_game_modal(assigns) do
    ~H"""
    <.game_modal id={"delete-game-modal-#{@game.id}"} game={@game}>
      <div class="flex flex-col gap-2">
        <p>
          You are about to <span class="font-bold">delete</span>
          the following game from your collection.
          <span class="font-bold">This action can't be undone </span>
          and you will lose all your data related with the game.
        </p>
      </div>
      <div class="flex justify-end w-full gap-2">
        <.button variant="error" phx-click="delete" phx-value-id={@game.id}>Confirm</.button>
        <.button href={~p"/backlog/collection/#{@game.id}"}>Cancel</.button>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game
  attr :current_scope, :map, required: true

  defp edit_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns =
      assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, platforms)
      |> assign(:statuses, statuses)

    ~H"""
    <.game_modal id={"edit-game-modal-#{@game.id}"} game={@game}>
      <:actions>
        <.button href={~p"/backlog/collection/#{@game.id}/images/edit"}>
          <.icon name="hero-photo" /> Images
        </.button>
      </:actions>

      <.form
        class="flex flex-col h-full justify-between"
        id={"edit-game-form-#{@game.id}"}
        phx-submit="update"
        for={@form}
      >
        <.input field={@form[:name]} label="Name" value={@game.name} autocomplete="off" />

        <div class="flex gap-2">
          <.input
            field={@form[:platform]}
            type="select"
            label="Platform"
            options={@platforms}
            value={@game.platform}
            fieldset_class="grow"
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={@statuses}
            value={@game.status}
            fieldset_class="grow"
          />
        </div>
        <div class="flex gap-1 relative">
          <.input
            field={@form[:cover]}
            label="Cover URL"
            placeholder="Cover URL"
            value={@game.cover}
            autocomplete="off"
          />
        </div>
        <div class="flex flex-col gap-1 relative">
          <.input
            field={@form[:hero]}
            label="Hero URL"
            placeholder="Hero URL"
            value={@game.hero}
            autocomplete="off"
          />
        </div>
        <div class="flex justify-end gap-2 mt-4">
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
          <.button variant="error" href={~p"/backlog/collection/#{@game.id}"}> Cancel</.button>
        </div>
      </.form>
    </.game_modal>
    """
  end

  defp status_badge(assigns = %{status: status}) do
    {label, _} = statuses() |> Map.get(status)

    color =
      case status do
        :completed -> "success"
        :in_progress -> "warning"
        :pending -> "info"
      end

    assigns = assign(assigns, %{label: label, color: color})

    ~H"""
    <.badge color={@color}>{@label}</.badge>
    """
  end

  defp platform_badge(assigns = %{platform: platform}) do
    {label, _} = platforms() |> Map.get(platform, "unknown")
    assigns = assign(assigns, :label, label)

    ~H"""
    <.badge color="neutral">{@label}</.badge>
    """
  end

  defp platforms() do
    %{
      pc: {"PC", :pc},
      ps1: {"PS1", :ps1},
      ps2: {"PS2", :ps2},
      ps3: {"PS3", :ps3},
      ps4: {"PS4", :ps4},
      ps5: {"PS5", :ps5},
      psp: {"PSP", :psp},
      switch: {"Switch", :switch}
    }
  end

  defp statuses() do
    %{
      completed: {"Completed", :completed},
      in_progress: {"In Progress", :in_progress},
      pending: {"Pending", :pending}
    }
  end
end
