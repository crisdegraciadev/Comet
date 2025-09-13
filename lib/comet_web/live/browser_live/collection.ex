defmodule CometWeb.BrowserLive.Collection do
  alias CometWeb.LiveComponents.AsyncGameCardComponent
  use CometWeb, :live_view

  alias Comet.Services.SGDB
  alias Comet.Games.Game

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @platforms %{
    pc: {"PC", :pc},
    ps1: {"PS1", :ps1},
    ps2: {"PS2", :ps2},
    ps3: {"PS3", :ps3},
    ps4: {"PS4", :ps4},
    ps5: {"PS5", :ps5},
    psp: {"PSP", :psp},
    switch: {"Switch", :switch}
  }

  @statuses %{
    completed: {"Completed", :completed},
    in_progress: {"In Progress", :in_progress},
    pending: {"Pending", :pending}
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["browser", "collection"]}
    >
      <.search_form api_key={@api_key} />
      <.search_results api_key={@api_key} results={@results} />

      <.add_game_modal
        :if={@live_action == :add}
        game={@selected_game}
        current_scope={@current_scope}
      />

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
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = Comet.Accounts.get_user_with_profile!(socket.assigns.current_scope.user.id)
    api_key = user.profile.api_key

    socket =
      assign(socket, %{
        api_key: api_key,
        results: [],
        loading: false,
        selected_game: nil,
        show_add_modal: false,
        show_image_selector: false,
        image_selector_field: nil,
        live_action: :list
      })

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    if game_json = Map.get(params, "game") do
      game =
        game_json
        |> URI.decode()
        |> Jason.decode!(keys: :atoms)

      {:noreply, assign(socket, selected_game: game, live_action: :add)}
    else
      {:noreply, assign(socket, selected_game: nil, live_action: :list)}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, %{assigns: %{api_key: api_key}} = socket) do
    case SGDB.search(query, api_key) do
      {:ok, results} -> {:noreply, assign(socket, results: results)}
      {:error, reason} -> {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp to_atom(str, default) when is_binary(str) do
    try do
      String.to_existing_atom(str)
    rescue
      ArgumentError -> default
    end
  end

  defp to_atom(atom, _default) when is_atom(atom), do: atom
  defp to_atom(_, default), do: default

  attr :field, :string, required: true
  attr :game_id, :any, required: true

  defp image_edit_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="suggest_images"
      phx-value-field={@field}
      phx-value-id={@game_id}
      class="absolute top-2 right-2 w-10 h-10 rounded-full flex items-center justify-center z-50 transition-colors duration-300"
      style="background-color: oklch(58% 0.233 277.117 / 0.5);"
      onmouseover="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.9)';"
      onmouseout="this.style.backgroundColor='oklch(58% 0.233 277.117 / 0.5)';"
    >
      <.icon name="hero-pencil" class="w-6 h-6 text-white" />
    </button>
    """
  end

  attr :api_key, :string, default: nil

  defp search_form(assigns) do
    assigns = assign(assigns, :form, to_form(%{"query" => ""}))

    ~H"""
    <div class="flex flex-col gap-4">
      <.form
        for={%{}}
        class="flex gap-2 items-center"
        id="search-form"
        phx-submit="search"
      >
        <.input
          field={@form[:query]}
          disabled={!@api_key}
          fieldset_class="grow !mb-0"
          placeholder="Search for games..."
          autocomplete="off"
          type="text"
        />
        <.button disabled={!@api_key} type="submit" phx-disable-with="Searching...">
          <.icon name="hero-magnifying-glass" /> Search
        </.button>
      </.form>

      <.alert :if={!@api_key} color="warning">
        <.icon name="hero-exclamation-triangle" class="w-6 h-6 text-white" />
        <span>
          You need to configure your SteamGridDB API key in
          <.link href={~p"/settings/api_key"} class="link link-primary">Settings</.link>
          to search for games.
        </span>
      </.alert>
    </div>
    """
  end

  defp search_results(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="text-xl font-semibold">Search Results</h2>

      <div class="grid grid-cols-10 gap-4">
        <.live_component
          :for={game <- @results}
          module={AsyncGameCardComponent}
          id={"async-game-card-#{game.id}"}
          game={game}
          api_key={@api_key}
        />
      </div>

      <div :if={@results == []} class="text-center py-8 text-base-content/70">
        No games found. Try a different search term.
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :game, :map, required: true
  attr :api_key, :string, default: nil

  defp game_card(assigns) do
    cover = SGDB.get_covers(assigns.game.id, assigns.api_key) |> cover()
    assigns = assigns |> assign(:cover, cover)

    ~H"""
    <div
      id={@id}
      phx-click="select_game"
      phx-value-game={Jason.encode!(@game)}
      class="cursor-pointer"
    >
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-base-300 relative">
        <!-- <div class="absolute top-2 left-2 flex gap-1 flex-col"> -->
        <!--   <.badge :if={@game.verified} color="success" size="xs">Verified</.badge> -->
        <!--   <.badge :if={@game.steam_id} color="info" size="xs">Steam</.badge> -->
        <!-- </div> -->

        <img
          class="aspect-2/3 rounded-tl-md rounded-tr-md"
          src={@cover.url}
          alt={@game.name}
        />

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@game.name}</span>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    status_atom =
      case assigns[:status] do
        s when is_atom(s) -> s
        _ -> :pending
      end

    {label, _} = Map.get(@statuses, status_atom, {"Pending", :pending})

    color =
      case status_atom do
        :completed -> "success"
        :in_progress -> "warning"
        _ -> "info"
      end

    assigns = assign(assigns, label: label, color: color)
    ~H"<.badge color={@color}>{@label}</.badge>"
  end

  defp platform_badge(assigns) do
    platform_atom =
      case assigns[:platform] do
        p when is_atom(p) -> p
        _ -> :pc
      end

    {label, _} = Map.get(@platforms, platform_atom, {"Unknown", :unknown})
    assigns = assign(assigns, label: label)
    ~H"<.badge color=\"neutral\">{@label}</.badge>"
  end

  # attr :id, :string, required: true
  # attr :game, :map, required: true
  # slot :inner_block
  # defp game_modal(assigns) do
  #   ~H"""
  #   <dialog id={@id} class="modal modal-open shadow-lg bg-transparent">
  #     <div class="game-modal modal-box w-1/2 max-w-[1920px] p-0 bg-cover bg-center relative" style={"background-image: url(#{@game.hero})"}>
  #       <.image_edit_button field="hero" game_id={@game.id} />
  #       <div class="card bg-base-100/75 w-fit">
  #         <div class="card-body">
  #           <div class="flex gap-8">
  #             <div class="relative w-[300px]">
  #               <img class="rounded-md game-cover-shadow w-full" src={@game.cover} />
  #               <.image_edit_button field="cover" game_id={@game.id} />
  #             </div>
  #             <div class="flex flex-col justify-between">
  #               <div class="flex flex-col gap-2 h-full">
  #                 <div class="flex flex-col gap-4">
  #                   <h1 class="limited-multiline-text font-semibold text-3xl">{@game.name}</h1>
  #                   <div class="flex gap-2 mb-2">
  #                     <.status_badge status={@game.status} />
  #                     <.platform_badge platform={@game.platform} />
  #                   </div>
  #                 </div>
  #                 <div class="h-full">
  #                   {render_slot(@inner_block)}
  #                 </div>
  #               </div>
  #             </div>
  #           </div>
  #         </div>
  #       </div>
  #     </div>
  #     <.link class="modal-backdrop" href={~p"/browser/collection"}></.link>
  #   </dialog>
  #   """
  # end

  attr :game, :map, required: true
  attr :current_scope, :map, required: true

  defp add_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)

    assigns =
      assigns
      |> assign(:changeset, changeset)
      |> assign(:platforms, Map.values(@platforms))
      |> assign(:statuses, Map.values(@statuses))

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
          <.input
            field={f[:cover]}
            label="Cover URL"
            placeholder="Cover URL"
            value={@game.cover}
            autocomplete="off"
          />
          <.input
            field={f[:hero]}
            label="Hero URL"
            placeholder="Hero URL"
            value={@game.hero}
            autocomplete="off"
          />
        </div>
        <div class="flex flex-col gap-2 mt-4">
          <.button variant="primary" type="submit" phx-disable-with="Adding...">Add</.button>
          <.button href={~p"/backlog/collection"}>Cancel</.button>
        </div>
      </.form>
    </.game_modal>
    """
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
  def handle_event("add_to_backlog", %{"game" => game_params}, socket) do
    user = socket.assigns.current_scope.user

    game_params =
      game_params
      |> Map.update("status", nil, &to_atom(&1, :pending))
      |> Map.update("platform", nil, &to_atom(&1, :pc))
      |> Map.put("steamgriddb_id", socket.assigns.selected_game.id)

    case Comet.Games.Game.Command.create(user, game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> put_flash(:info, "Game added to backlog")
         |> assign(live_action: :list)
         |> push_navigate(to: ~p"/backlog/collection")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("suggest_images", %{"field" => field}, socket) do
    {:noreply, assign(socket, show_image_selector: true, image_selector_field: field)}
  end

  @impl true
  def handle_info({:image_selected, field, url}, socket) do
    key =
      case field do
        "cover" -> :cover
        "hero" -> :hero
      end

    {:noreply,
     socket
     |> assign(show_image_selector: false, image_selector_field: nil)
     |> update(:selected_game, fn game -> Map.put(game, key, url) end)}
  end

  defp cover(covers) do
    covers
    |> Enum.map(fn cover -> %{url: cover[:url], style: cover[:style]} end)
    |> Enum.find(Enum.at(covers, 0), fn cover -> cover.style == "official" end)
  end
end
