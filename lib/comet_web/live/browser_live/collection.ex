defmodule CometWeb.BrowserLive.Collection do
  use CometWeb, :live_view
  alias Comet.Services.SteamGridDB
  alias Comet.Games.Game

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

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

        <.loading_indicator :if={@loading} />

        <.search_results :if={@search_results} results={@search_results} />

        <.game_details_modal :if={@selected_game} game={@selected_game} />
        <.add_to_backlog_modal :if={@show_add_modal} game={@selected_game} current_scope={@current_scope} />
        <.image_selector_modal :if={@show_image_selector} field={@image_selector_field} images={@image_options} />
      </Layouts.app>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user |> Comet.Repo.preload(profile: :user)
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
      |> assign(:image_options, [])

    {:ok, socket}
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

      <.form for={%{}} class="flex gap-2" id="search-form" phx-submit="search">
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
        <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" /></svg>
        <span>You need to configure your SteamGridDB API key in
        <.link href={~p"/settings/api_key"} class="link link-primary">Settings</.link>
        to search for games.</span>
      </div>
    </div>
    """
  end

  defp loading_indicator(assigns) do
    ~H"""
    <div class="flex justify-center items-center py-8">
      <div class="loading loading-spinner loading-lg"></div>
      <span class="ml-2">Searching for games...</span>
    </div>
    """
  end

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
    <div id={@id} phx-click="select_game" phx-value-game-id={@game.id} class="cursor-pointer">
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

  attr :game, :map, required: true
  defp game_details_modal(assigns) do
    ~H"""
    <dialog id="game-details-modal" class="modal modal-open">
      <div class="modal-box max-w-2xl relative" style={"background-image: url('#{@game.hero || @game.cover_url}'); background-size: cover; background-position: center;"}>
        <div class="flex justify-between items-start mb-4">
          <h2 class="text-2xl font-bold">{@game.name}</h2>
          <.button phx-click="close_modal" variant="ghost" size="sm">
            <.icon name="hero-x-mark" />
          </.button>
        </div>

        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <.badge :if={@game.verified} color="success">Verified</.badge>
            <.badge :if={@game.steam_id} color="info">Steam ID: {@game.steam_id}</.badge>
            <.badge :if={@game.types != []} color="neutral">
              <%= Enum.join(@game.types, ", ") %>
            </.badge>
          </div>

          <div :if={@game.release_date} class="text-sm text-base-content/70">
            Release Date: <%= format_release_date(@game.release_date) %>
          </div>

          <div class="flex gap-2">
            <.button phx-click="show_add_modal" variant="primary">
              <.icon name="hero-plus" />
              Add to Backlog
            </.button>
            <.button :if={@game.steam_id} phx-click="view_on_steam" variant="ghost">
              <.icon name="hero-arrow-top-right-on-square" />
              View on Steam
            </.button>
          </div>
        </div>
      </div>

      <div class="modal-backdrop" phx-click="close_modal"></div>
    </dialog>
    """
  end

  attr :game, :map, required: true
  attr :current_scope, :map, required: true
  defp add_to_backlog_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)
    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns =
      assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, platforms)
      |> assign(:statuses, statuses)

    ~H"""
    <dialog id="add-to-backlog-modal" class="modal modal-open">
      <div class="modal-box max-w-md relative">
        <h3 class="font-bold text-lg mb-4">Add {@game.name} to Backlog</h3>

        <.form
          class="space-y-4"
          id="add-game-form"
          phx-submit="add_to_backlog"
          for={@form}
        >
          <.input field={@form[:name]} label="Game Name" value={@game.name} />

          <div class="flex gap-2">
            <.input field={@form[:platform]} type="select" label="Platform" options={@platforms} fieldset_class="grow" />
            <.input field={@form[:status]} type="select" label="Status" options={@statuses} fieldset_class="grow" />
          </div>

          <div class="flex flex-col gap-1">
            <.input field={@form[:cover]} label="Cover URL" placeholder="Will be auto-filled from SteamGridDB" value={@game.cover_url} />
            <.button type="button" phx-click="suggest_images" phx-value-field="cover" class="mt-1">Cover suggestions</.button>
          </div>

          <div class="flex flex-col gap-1">
            <.input field={@form[:hero]} label="Hero URL" placeholder="Will be auto-filled from SteamGridDB" value={@game.hero || @game.cover_url} />
            <.button type="button" phx-click="suggest_images" phx-value-field="hero" class="mt-1">Hero suggestions</.button>
          </div>

          <div class="flex gap-2">
            <.button type="submit" variant="primary" phx-disable-with="Adding...">Add to Backlog</.button>
            <.button type="button" phx-click="close_add_modal" variant="ghost">Cancel</.button>
          </div>
        </.form>
      </div>

      <div class="modal-backdrop" phx-click="close_add_modal"></div>
    </dialog>
    """
  end

  attr :field, :string, required: true
  attr :images, :list, required: true
  defp image_selector_modal(assigns) do
    ~H"""
    <dialog id="image-selector-modal" class="modal modal-open">
      <div class="modal-box max-w-3xl relative">
        <h3 class="font-bold text-lg mb-4">Select Image for {@field}</h3>
        <div class="grid grid-cols-6 gap-4">
          <img :for={img <- @images} src={img} class="cursor-pointer rounded" phx-click="select_image" phx-value-url={img} phx-value-field={@field} />
        </div>
        <.button type="button" phx-click="close_image_selector" variant="ghost" class="mt-4">Close</.button>
      </div>
      <div class="modal-backdrop" phx-click="close_image_selector"></div>
    </dialog>
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
    if socket.assigns.api_key && socket.assigns.api_key != "" do
      socket = assign(socket, :loading, true) |> assign(:search_query, query)

      case SteamGridDB.search_games_with_covers(query, socket.assigns.api_key) do
        {:ok, results} ->
          results_with_heroes =
            Enum.map(results, fn game ->
              hero_url = SteamGridDB.get_hero(game.id, socket.assigns.api_key) || game.cover_url
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
    else
      {:noreply, put_flash(socket, :error, "Please configure your SteamGridDB API key first")}
    end
  end

  @impl true
  def handle_event("select_game", %{"game-id" => game_id}, socket) do
    game =
      Enum.find(socket.assigns.search_results, &(&1.id == String.to_integer(game_id)))
    {:noreply, assign(socket, :selected_game, game)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :selected_game, nil)}
  end

  @impl true
  def handle_event("show_add_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_modal, true)}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_modal, false)}
  end

  @impl true
  def handle_event("view_on_steam", _params, socket) do
    game = socket.assigns.selected_game
    steam_url = "https://store.steampowered.com/app/#{game.steam_id}"

    {:noreply,
     socket
     |> push_event("open_url", %{url: steam_url})
     |> assign(:selected_game, nil)}
  end

  @impl true
  def handle_event("add_to_backlog", %{"game" => game_params}, socket) do
    selected_game = socket.assigns.selected_game

    game_attrs = %{
      name: game_params["name"] || selected_game.name,
      platform: String.to_existing_atom(game_params["platform"]),
      status: String.to_existing_atom(game_params["status"]),
      cover: game_params["cover"] || selected_game.cover_url,
      hero: game_params["hero"] || selected_game.hero || selected_game.cover_url,
      steamgriddb_id: selected_game.id
    }

    case Game.Command.create(socket.assigns.current_scope.user, game_attrs) do
      {:ok, created_game} ->
        {:noreply,
        socket
        |> put_flash(:info, "#{created_game.name} added to backlog!")
        |> assign(:selected_game, nil)
        |> assign(:show_add_modal, false)
        |> push_navigate(to: ~p"/backlog/collection", replace: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add game to backlog")}
    end
  end

  @impl true
  def handle_event("suggest_images", %{"field" => field, "value" => _value}, socket) do
    selected_game = socket.assigns.selected_game
    api_key = socket.assigns.api_key

    images =
      case field do
        "cover" -> List.wrap(Comet.Services.SteamGridDB.get_all_covers(selected_game.id, api_key))
        "hero" -> List.wrap(Comet.Services.SteamGridDB.get_all_heroes(selected_game.id, api_key))
      end
      |> Enum.filter(& &1)
      |> Enum.uniq()

    {:noreply,
    assign(socket,
      show_image_selector: true,
      image_selector_field: field,
      image_options: images
    )}
  end


  @impl true
  def handle_event("select_image", %{"url" => url, "field" => field}, socket) do
    key =
      case field do
        "cover" -> :cover_url
        "hero" -> :hero
      end

    {:noreply,
    socket
    |> assign(:show_image_selector, false)
    |> assign(:image_selector_field, nil)
    |> assign(:image_options, [])
    |> update(:selected_game, fn game ->
      Map.put(game, key, url)
    end)}
  end

  @impl true
  def handle_event("close_image_selector", _params, socket) do
    {:noreply, assign(socket, :show_image_selector, false)}
  end
end
