defmodule CometWeb.BacklogLive.Collection do
  alias Comet.Games
  alias Comet.Games.Game
  alias Comet.Services.SteamGridDB

  use CometWeb, :live_view

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
      <.image_selector_modal :if={@show_image_selector} images={@image_options} field={@image_selector_field} />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{live_action: :list, current_scope: %{user: user}}} = socket) do
    user = Comet.Repo.preload(user, :profile)

    {:ok,
    socket
    |> stream(:game_list, Game.Query.all(user))
    |> assign(:current_scope, %{user: user})
    |> assign(:show_image_selector, false)
    |> assign(:image_selector_field, nil)
    |> assign(:image_options, [])}
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket)
      when live_action != :list do
    user = Comet.Repo.preload(user, :profile)
    game = Game.Query.get!(user, String.to_integer(id))

    {:ok,
    socket
    |> stream(:game_list, Game.Query.all(user))
    |> assign(:current_scope, %{user: user})
    |> assign(:game, game)
    |> assign(:show_image_selector, false)
    |> assign(:image_selector_field, nil)
    |> assign(:image_options, [])}
  end

  defp filters(assigns) do
    form = to_form(%{"name" => "", "platform" => "", "status" => ""})
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns = assign(assigns, %{form: form, platforms: platforms, statuses: statuses})

    ~H"""
    <.form class="flex gap-2" id="filter-form" phx-change="filter" for={@form}>
      <.input field={@form[:platform]} fieldset_class="w-1/8" type="select" options={@platforms} prompt="Platform" />
      <.input field={@form[:status]} fieldset_class="w-1/8" type="select" options={@statuses} prompt="Status" />
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
      <div class="rounded-md flex flex-col gap-2 game-cover bg-base-300 relative">
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
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <p class="font-semibold text-md">Game Status</p>
          <.button phx-click="change_status" phx-value-status="pending" class="hover:btn-info focus:btn-info" variant={@game.status == :pending && "info"} soft={@game.status != :pending}>Pending</.button>
          <.button phx-click="change_status" phx-value-status="in_progress" class="hover:btn-warning focus:btn-warning" variant={@game.status == :in_progress && "warning"} soft={@game.status != :in_progress}>In Progress</.button>
          <.button phx-click="change_status" phx-value-status="completed" class="hover:btn-success focus:btn-success" variant={@game.status == :completed && "success"} soft={@game.status != :completed}>Completed</.button>
        </div>
        <div class="flex flex-col gap-2">
          <.button href={~p"/backlog/collection/#{@game}/edit"}>Edit</.button>
          <.button variant="error" href={~p"/backlog/collection/#{@game}/delete"}>Delete</.button>
        </div>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game
  defp delete_game_modal(assigns) do
    ~H"""
    <.game_modal id={"delete-game-modal-#{@game.id}"} game={@game}>
      <div class="flex flex-col justify-between h-full max-w-sm">
        <div class="flex flex-col gap-2">
          <p>You are about to <span class="font-bold">delete</span> the following game from your collection.</p>
          <p><span class="font-bold">This action can't be undone </span> and you will lose all your data related with the game.</p>
          <p>Confirm the operation or cancel it.</p>
        </div>
        <div class="flex flex-col gap-2">
          <.button variant="error" phx-click="delete" phx-value-id={@game.id}>Delete</.button>
          <.button href={~p"/backlog/collection/#{@game.id}"}> Cancel</.button>
        </div>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game
  attr :current_scope, :map, default: nil
  defp edit_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns = assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, platforms)
      |> assign(:statuses, statuses)

    ~H"""
    <.game_modal id={"edit-game-modal-#{@game.id}"} game={@game}>
      <.form class="flex flex-col h-full justify-between" id={"edit-game-form-#{@game.id}"} phx-submit="update" for={@form}>
        <div>
          <.input field={@form[:name]} label="Name" value={@game.name} autocomplete="off" />
          <div class="flex gap-2">
            <.input field={@form[:platform]} type="select" label="Platform" options={@platforms} value={@game.platform} fieldset_class="grow" />
            <.input field={@form[:status]} type="select" label="Status" options={@statuses} value={@game.status} fieldset_class="grow" />
          </div>
          <div class="flex flex-col gap-1">
            <.input field={@form[:cover]} label="Cover URL" placeholder="Cover URL" value={@game.cover} autocomplete="off" />
          </div>
          <div class="flex flex-col gap-1">
            <.input field={@form[:hero]} label="Hero URL" placeholder="Hero URL" value={@game.hero} autocomplete="off" />
          </div>
        </div>
        <div class="flex flex-col gap-2 mt-4">
          <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          <.button href={~p"/backlog/collection/#{@game.id}"}> Cancel</.button>
        </div>
      </.form>
    </.game_modal>
    """
  end

  attr :id, :string, required: true
  attr :game, Game, required: true
  slot :inner_block
  defp game_modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal modal-open shadow-lg bg-transparent">
      <div class="game-modal modal-box w-1/2 max-w-[1920px] p-0 bg-cover bg-center relative" style={"background-image: url(#{@game.hero})"}>
        <button
          type="button"
          phx-click="suggest_images"
          phx-value-field="hero"
          phx-value-id={@game.id}
          class="absolute top-2 right-2 w-10 h-10 rounded-full flex items-center justify-center z-50 transition-colors duration-300"
          style="background-color: oklch(58% 0.233 277.117 / 0.5);"
          onmouseover="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.9)';"
          onmouseout="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.5)';"
        >
          <.icon name="hero-pencil" class="w-6 h-6 text-white" />
        </button>
        <div class="card bg-base-100/75 w-fit">
          <div class="card-body">
            <div class="flex gap-8">
              <div class="relative w-[300px]">
                <img class="rounded-md game-cover w-full" src={@game.cover} />
                <button
                  type="button"
                  phx-click="suggest_images"
                  phx-value-field="cover"
                  phx-value-id={@game.id}
                  class="absolute top-2 right-2 w-10 h-10 rounded-full flex items-center justify-center z-50 transition-colors duration-300"
                  style="background-color: oklch(58% 0.233 277.117 / 0.5);"
                  onmouseover="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.9)';"
                  onmouseout="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.5)';"
                >
                  <.icon name="hero-pencil" class="w-6 h-6 text-white" />
                </button>
              </div>
              <div class="flex flex-col justify-between">
                <div class="flex flex-col gap-2 h-full">
                  <div class="flex flex-col gap-4">
                    <h1 class="limited-multiline-text font-semibold text-3xl">{@game.name}</h1>
                    <div class="flex gap-2 mb-2">
                      <.status_badge status={@game.status} />
                      <.platform_badge platform={@game.platform} />
                    </div>
                  </div>
                  <div class="h-full">
                    {render_slot(@inner_block)}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <.link class="modal-backdrop" href={~p"/backlog/collection"}></.link>
    </dialog>
    """
  end

  defp image_selector_modal(assigns) do
    ~H"""
    <dialog id="image-selector" class="modal modal-open shadow-lg bg-transparent">
      <div class="modal-box w-1/2 max-w-[1280px]">
        <h2 class="font-semibold mb-4">Select an image</h2>
        <div class="grid grid-cols-4 gap-4">
          <img :for={img <- @images} src={img} class="cursor-pointer rounded" phx-click="select_image" phx-value-url={img} phx-value-field={@field} />
        </div>
        <div class="mt-4 flex justify-end">
          <.button phx-click="close_image_selector">Close</.button>
        </div>
      </div>
    </dialog>
    """
  end

  defp status_badge(assigns = %{status: status}) do
    {label, _} = statuses() |> Map.get(status)
    color = case status do
      :completed -> "success"
      :in_progress -> "warning"
      :pending -> "info"
    end
    assigns = assign(assigns, %{label: label, color: color})
    ~H"<.badge color={@color}>{@label}</.badge>"
  end

  defp platform_badge(assigns = %{platform: platform}) do
    {label, _} = platforms() |> Map.get(platform, "unknown")
    assigns = assign(assigns, :label, label)
    ~H"<.badge color='neutral'>{@label}</.badge>"
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

  @impl true
  def handle_event("filter", params, %{assigns: %{current_scope: %{user: user}}} = socket) do
    socket = socket
    |> assign(:form, to_form(params))
    |> stream(:game_list, Game.Query.all(user, params), reset: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    game = Game.Query.get!(user, id)
    Game.Command.delete!(game)
    socket = socket |> stream_delete(:game_list, game) |> put_flash(:info, "Game deleted") |> push_navigate(to: ~p"/backlog/collection", replace: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("update", %{"game" => game_params}, %{assigns: %{game: game, current_scope: current_scope}} = socket) do
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, game_params)
    socket = socket |> assign(:game, updated_game) |> put_flash(:info, "Game updated!") |> push_navigate(to: ~p"/backlog/collection/#{updated_game.id}", replace: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_status", %{"status" => status}, %{assigns: %{game: game, current_scope: current_scope}} = socket) do
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, %{status: status})
    socket = socket |> assign(:game, updated_game) |> stream_insert(:game_list, updated_game)
    {:noreply, socket}
  end

  @impl true
  def handle_event("suggest_images", %{"field" => field}, socket) do
    selected_game = socket.assigns.game
    api_key = socket.assigns.current_scope.user.profile.api_key
    images =
      case field do
        "cover" -> List.wrap(SteamGridDB.get_all_covers(selected_game.steamgriddb_id, api_key))
        "hero"  -> List.wrap(SteamGridDB.get_all_heroes(selected_game.steamgriddb_id, api_key))
      end
      |> Enum.filter(& &1)
      |> Enum.uniq()
    {:noreply, assign(socket, show_image_selector: true, image_selector_field: field, image_options: images)}
  end

  @impl true
  def handle_event("select_image", %{"url" => url, "field" => field}, %{assigns: %{game: game, current_scope: current_scope}} = socket) do
    key = case field do "cover" -> :cover; "hero" -> :hero end
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, %{key => url})
    {:noreply, socket |> assign(:show_image_selector, false) |> assign(:image_selector_field, nil) |> assign(:image_options, []) |> assign(:game, updated_game) |> stream_insert(:game_list, updated_game)}
  end

  @impl true
  def handle_event("close_image_selector", _, socket) do
    {:noreply, socket |> assign(:show_image_selector, false) |> assign(:image_selector_field, nil) |> assign(:image_options, [])}
  end
end
