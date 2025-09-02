defmodule CometWeb.BrowserLive.Collection do
  use CometWeb, :live_view
  alias Comet.Services.SteamGridDB
  alias Comet.Games.Game

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def mount(_params, _session, socket) do
    user = Comet.Accounts.get_user_with_profile!(socket.assigns.current_scope.user.id)
    api_key = user.profile.api_key

    socket =
      socket
      |> assign(:api_key, api_key)
      |> assign(:search_query, "")
      |> assign(:search_results, nil)
      |> assign(:loading, false)
      |> assign(:selected_game, nil)
      |> assign(:show_add_modal, false)
      |> assign(:show_image_selector, false)
      |> assign(:image_selector_field, nil)
      |> assign(:live_action, :list)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"game" => game_json}, _uri, socket) do
    game_json
    |> URI.decode()
    |> Jason.decode!(keys: :atoms)
    |> then(fn game ->
      {:noreply, assign(socket, selected_game: game, live_action: :add)}
    end)
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, selected_game: nil, live_action: :list)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="browser-container" phx-hook="OpenUrl">
      <Layouts.app
        flash={@flash}
        current_scope={@current_scope}
        current_module={["browser", "collection"]}
      >
        <.search_form api_key={@api_key} search_query={@search_query} />

        <.loading_indicator :if={@loading} loading={@loading} />

        <.search_results :if={@search_results} results={@search_results} />

        <.add_game_modal :if={@live_action == :add && @selected_game} game={@selected_game} current_scope={@current_scope} />

        <.live_component
          :if={@selected_game}
          module={CometWeb.LiveComponents.ImageSelectorComponent}
          id={"image-selector-#{@selected_game.id}"}
          game={@selected_game}
          field={@image_selector_field}
          api_key={@api_key}
          show={@show_image_selector}
        />
      </Layouts.app>
    </div>
    """
  end

  attr :api_key, :string, default: nil
  attr :search_query, :string, default: ""
  defp search_form(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <.header>
        Game Browser
        <:subtitle>Search for games on SteamGridDB</:subtitle>
      </.header>

      <.form :if={@api_key != nil and @api_key != ""} for={%{}} class="flex gap-2" id="search-form" phx-submit="search">
        <.input
          name="query"
          fieldset_class="grow"
          placeholder="Search for games..."
          autocomplete="off"
          value={@search_query}
        />
        <.button type="submit" phx-disable-with="Searching...">
          <.icon name="hero-magnifying-glass" />
          Search
        </.button>
      </.form>

      <div :if={@api_key == nil or @api_key == ""} class="alert alert-warning">
        <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-white" />
        <span>
          You need to configure your SteamGridDB API key in
          <.link href={~p"/settings/api_key"} class="link link-primary">Settings</.link>
          to search for games.
        </span>
      </div>
    </div>
    """
  end

  attr :loading, :boolean, default: false
  defp loading_indicator(assigns) do
    ~H"""
    <div class="flex justify-center items-center py-8">
      <div class="loading loading-spinner loading-lg"></div>
      <span class="ml-2">Searching for games...</span>
    </div>
    """
  end

  attr :results, :list, required: true
  defp search_results(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-xl font-semibold">Search Results</h2>

      <div class="grid grid-cols-8 gap-4">
        <.game_card :for={game <- @results} id={"game-#{game.id}"} game={game} />
      </div>

      <div :if={@results == []} class="text-center py-8 text-base-content/70">
        No games found. Try a different search term.
      </div>
    </div>
    """
  end

  attr :game, :map, required: true
  attr :id, :string, required: true
  defp game_card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-click="select_game"
      phx-value-game={Jason.encode!(@game)}
      class="cursor-pointer"
    >
      <div class="rounded-md flex flex-col gap-2 game-cover bg-base-300 relative">
        <div class="absolute top-2 left-2 flex gap-1 flex-col">
          <.badge :if={@game.verified} color="success" size="xs">Verified</.badge>
          <.badge :if={@game.steam_id} color="info" size="xs">Steam</.badge>
        </div>

        <img
          class="aspect-2/3 rounded-tl-md rounded-tr-md"
          src={@game.cover_url}
          alt={@game.name}
        />

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@game.name}</span>
      </div>
    </div>
    """
  end

  defp status_badge(assigns = %{status: status}) do
    status_atom =
      case status do
        s when is_binary(s) ->
          try do
            String.to_existing_atom(s)
          rescue
            ArgumentError -> :pending
          end

        s when is_atom(s) -> s
        _ -> :pending
      end
    {label, _} = Map.get(statuses(), status_atom, {"Pending", :pending})

    color = case status_atom do
      :completed -> "success"
      :in_progress -> "warning"
      _ -> "info"
    end

    assigns = assign(assigns, %{label: label, color: color})

    ~H"<.badge color={@color}>{@label}</.badge>"
  end


  defp platform_badge(assigns = %{platform: platform}) do
    platform_atom =
      case platform do
        p when is_binary(p) ->
          try do
            String.to_existing_atom(p)
          rescue
            ArgumentError -> :pc
          end

        p when is_atom(p) -> p
        _ -> :pc
      end

    {label, _} = Map.get(platforms(), platform_atom, {"Unknown", :unknown})

    assigns = assign(assigns, :label, label)
    ~H"<.badge color='neutral'>{@label}</.badge>"
  end

  attr :id, :string, required: true
  attr :game, :map, required: true
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
      <.link class="modal-backdrop" href={~p"/browser/collection"}></.link>
    </dialog>
    """
  end

  attr :game, :map, required: true
  attr :current_scope, :map, required: true
  defp add_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns =
      assigns
      |> assign(:changeset, changeset)
      |> assign(:platforms, platforms)
      |> assign(:statuses, statuses)

    ~H"""
    <.game_modal id={"add-game-modal-#{@game.id}"} game={@game}>
      <.form :let={f} for={@changeset} id={"add-game-form-#{@game.id}"} phx-submit="add_to_backlog">
        <div>
          <.input field={f[:name]} label="Name" value={@game.name} autocomplete="off" />
          <div class="flex gap-2">
            <.input
              field={f[:platform]}
              type="select"
              label="Platform"
              options={@platforms}
              value={@game.platform}
              fieldset_class="grow"
            />
            <.input
              field={f[:status]}
              type="select"
              label="Status"
              options={@statuses}
              value={@game.status}
              fieldset_class="grow"
            />
          </div>
          <div class="flex flex-col gap-1 relative">
            <.input field={f[:cover]} label="Cover URL" placeholder="Cover URL" value={@game.cover} autocomplete="off" />
          </div>
          <div class="flex flex-col gap-1 relative">
            <.input field={f[:hero]} label="Hero URL" placeholder="Hero URL" value={@game.hero} autocomplete="off" />
          </div>
        </div>
        <div class="flex flex-col gap-2 mt-4">
          <.button variant="primary" type="submit" phx-disable-with="Adding...">Add</.button>
          <.button href={~p"/backlog/collection"}>Cancel</.button>
        </div>
      </.form>
    </.game_modal>
    """
  end


  defp platforms do
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

  defp statuses do
    %{
      completed: {"Completed", :completed},
      in_progress: {"In Progress", :in_progress},
      pending: {"Pending", :pending}
    }
  end

  defp format_release_date(nil), do: nil
  defp format_release_date(timestamp) do
    timestamp
    |> DateTime.from_unix!()
    |> DateTime.to_date()
    |> then(&"#{pad(&1.day)}/#{pad(&1.month)}/#{&1.year}")
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    socket = assign(socket, :loading, true) |> assign(:search_query, query)

    case SteamGridDB.search_games_with_covers(query, socket.assigns.api_key) do
      {:ok, results} ->
        results_with_heroes =
          Enum.map(results, fn game ->
            hero_url = SteamGridDB.get_hero(game.id, socket.assigns.api_key)
            Map.put(game, :hero, hero_url)
          end)

        {:noreply,
         socket
         |> assign(:search_results, results_with_heroes)
         |> assign(:loading, false)
         |> put_flash(:info, "Found #{length(results_with_heroes)} games")}

      {:error, message} ->
        {:noreply, assign(socket, :loading, false) |> put_flash(:error, message)}
    end
  end

  @impl true
  def handle_event("select_game", %{"game" => game_json}, socket) do
    {:ok, game} = Jason.decode(game_json, keys: :atoms)

    game =
      game
      |> Map.put_new(:status, :pending)
      |> Map.put_new(:cover, Map.get(game, :cover_url))
      |> Map.delete(:cover_url)
      |> Map.put_new(:platform, :pc)

    {:noreply,
    push_patch(socket, to: ~p"/browser/collection/new?game=#{URI.encode(Jason.encode!(game))}")}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, selected_game: nil)}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply, assign(socket, selected_game: nil, live_action: :list)}
  end

  @impl true
  def handle_event("create_game", %{"game" => game_params}, socket) do
    selected_game = socket.assigns.selected_game

    game_attrs = %{
      name: game_params["name"] || selected_game.name,
      platform: game_params["platform"],
      status: game_params["status"],
      cover: game_params["cover"],
      hero: game_params["hero"],
      steamgriddb_id: selected_game.id
    }

    case Game.Command.create(socket.assigns.current_scope.user, game_attrs) do
      {:ok, created_game} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{created_game.name} added to backlog!")
         |> assign(:selected_game, nil)
         |> assign(:live_action, :list)
         |> push_navigate(to: ~p"/backlog/collection")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add game to backlog")}
    end
  end

  @impl true
  def handle_event("suggest_images", %{"field" => field}, socket) do
    {:noreply, assign(socket, show_image_selector: true, image_selector_field: field)}
  end

  @impl true
  def handle_info({:image_selected, field, url}, socket) do
    key = case field do
      "cover" -> :cover
      "hero" -> :hero
    end

    {:noreply,
     socket
     |> assign(:show_image_selector, false)
     |> assign(:image_selector_field, nil)
     |> update(:selected_game, fn game -> Map.put(game, key, url) end)}
  end

  def handle_event("add_to_backlog", %{"game" => game_params}, socket) do
    user = socket.assigns.current_scope.user

    game_params =
      game_params
      |> Map.update("status", nil, &String.to_existing_atom/1)
      |> Map.update("platform", nil, &String.to_existing_atom/1)
      |> Map.put("steamgriddb_id", socket.assigns.selected_game.id)

    case Comet.Games.Game.Command.create(user, game_params) do
      {:ok, _game} ->
        {:noreply,
        socket
        |> put_flash(:info, "Game added to backlog")
        |> assign(:live_action, :list)
        |> push_navigate(to: ~p"/backlog/collection")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end


end
