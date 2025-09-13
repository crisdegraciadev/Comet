defmodule CometWeb.BrowserLive.Collection do
  use CometWeb, :live_view

  alias Comet.Services.SGDB
  alias Comet.Services.Constants
  alias Comet.Games.Game
  alias CometWeb.LiveComponents

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    IO.inspect(assigns)

    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["browser", "collection"]}
    >
      <.search_form api_key={@api_key} />
      <.search_results api_key={@api_key} results={assigns[:results]} query={assigns[:query]} />

      <.add_game_modal
        :if={@live_action == :new}
        game={@game}
        current_scope={@current_scope}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id, "query" => query}, _session, %{assigns: %{live_action: :new}} = socket) do
    api_key = load_api_key(socket)

    {:ok, %{game: %{id: id, name: name}}} = SGDB.get_game(id, api_key)
    {:ok, %{covers: covers}} = SGDB.get_covers(id, api_key)
    {:ok, %{heroes: heroes}} = SGDB.get_heroes(id, api_key)

    game = %Game{
      id: -1,
      steamgriddb_id: id,
      name: name,
      cover: main_asset_url(covers),
      hero: main_asset_url(heroes)
    }

    socket = socket |> assign(:api_key, api_key) |> assign(:game, game)

    socket =
      case SGDB.search(query, api_key) do
        {:ok, results} -> socket |> assign(:results, results)
        {:error, reason} -> socket |> put_flash(:error, reason)
      end

    {:ok, socket}
  end

  @impl true
  def mount(%{"query" => query}, _session, socket) do
    api_key = load_api_key(socket)

    socket = assign(socket, :api_key, api_key)

    socket =
      case SGDB.search(query, api_key) do
        {:ok, results} -> socket |> assign(:results, results)
        {:error, reason} -> socket |> put_flash(:error, reason)
      end

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    api_key = load_api_key(socket)

    socket = socket |> assign(:api_key, api_key)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"query" => query}, _session, socket) do
    {:noreply, assign(socket, :query, query)}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/browser/collection?query=#{query}", replace: true)}
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

  defp search_results(%{results: nil} = assigns) do
    ~H"""
    <div class="text-center py-8 text-base-content/70">
      No Results
    </div>
    """
  end

  defp search_results(%{results: []} = assigns) do
    ~H"""
    <div class="text-center py-8 text-base-content/70">
      No games found. Try a different search term.
    </div>
    """
  end

  defp search_results(assigns) do
    IO.inspect(assigns.results, label: "results-label")

    ~H"""
    <div class="grid grid-cols-10 gap-4">
      <.link
        :for={game <- @results}
        navigate={~p"/browser/collection/#{game.id}/new?query=#{@query}"}
      >
        <.live_component
          module={LiveComponents.ResultGameCardComponent}
          id={game.id}
          game={game}
          api_key={@api_key}
        />
      </.link>
    </div>
    """
  end

  attr :game, :map
  attr :current_scope, :map, required: true

  defp add_game_modal(assigns) do
    ~H"""
    <.game_modal id={"edit-game-modal-#{@game.id}"} game={@game}>
      <!-- <:actions> -->
      <!--   <.button href={~p"/backlog/collection/#{@game.id}/images/edit"}> -->
      <!--     <.icon name="hero-photo" /> Images -->
      <!--   </.button> -->
      <!-- </:actions> -->

      <!-- <.form -->
      <!--   class="flex flex-col h-full justify-between" -->
      <!--   id={"edit-game-form-#{@game.id}"} -->
      <!--   phx-submit="update" -->
      <!--   for={@form} -->
      <!-- > -->
      <!--   <.input field={@form[:name]} label="Name" value={@game.name} autocomplete="off" /> -->
      <!---->
      <!--   <div class="flex gap-2"> -->
      <!--     <.input -->
      <!--       field={@form[:platform]} -->
      <!--       type="select" -->
      <!--       label="Platform" -->
      <!--       options={@platforms} -->
      <!--       value={@game.platform} -->
      <!--       fieldset_class="grow" -->
      <!--     /> -->
      <!--     <.input -->
      <!--       field={@form[:status]} -->
      <!--       type="select" -->
      <!--       label="Status" -->
      <!--       options={@statuses} -->
      <!--       value={@game.status} -->
      <!--       fieldset_class="grow" -->
      <!--     /> -->
      <!--   </div> -->
      <!--   <div class="flex gap-1 relative"> -->
      <!--     <.input -->
      <!--       field={@form[:cover]} -->
      <!--       label="Cover URL" -->
      <!--       placeholder="Cover URL" -->
      <!--       value={@game.cover} -->
      <!--       autocomplete="off" -->
      <!--     /> -->
      <!--   </div> -->
      <!--   <div class="flex flex-col gap-1 relative"> -->
      <!--     <.input -->
      <!--       field={@form[:hero]} -->
      <!--       label="Hero URL" -->
      <!--       placeholder="Hero URL" -->
      <!--       value={@game.hero} -->
      <!--       autocomplete="off" -->
      <!--     /> -->
      <!--   </div> -->
      <!--   <div class="flex justify-end gap-2 mt-4"> -->
      <!--     <.button type="submit" phx-disable-with="Saving...">Save</.button> -->
      <!--     <.button variant="error" href={~p"/backlog/collection/#{@game.id}"}> Cancel</.button> -->
      <!--   </div> -->
      <!-- </.form> -->
    </.game_modal>
    """
  end

  # @impl true
  # def handle_event("select_game", %{"game" => game_json}, socket) do
  #   {:ok, game} = Jason.decode(game_json, keys: :atoms)
  #
  #   game =
  #     game
  #     |> Map.put_new(:status, :pending)
  #     |> Map.put_new(:cover, Map.get(game, :cover_url))
  #     |> Map.delete(:cover_url)
  #     |> Map.put_new(:platform, :pc)
  #
  #   {:noreply,
  #    push_patch(socket, to: ~p"/browser/collection/new?game=#{URI.encode(Jason.encode!(game))}")}
  # end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, selected_game: nil)}
  end

  @impl true
  def handle_event("close_add_modal", _params, socket) do
    {:noreply, assign(socket, selected_game: nil, live_action: :list)}
  end

  # @impl true
  # def handle_event("add_to_backlog", %{"game" => game_params}, socket) do
  #   user = socket.assigns.current_scope.user
  #
  #   game_params =
  #     game_params
  #     |> Map.update("status", nil, &to_atom(&1, :pending))
  #     |> Map.update("platform", nil, &to_atom(&1, :pc))
  #     |> Map.put("steamgriddb_id", socket.assigns.selected_game.id)
  #
  #   case Comet.Games.Game.Command.create(user, game_params) do
  #     {:ok, _game} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Game added to backlog")
  #        |> assign(live_action: :list)
  #        |> push_navigate(to: ~p"/backlog/collection")}
  #
  #     {:error, changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

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

  defp load_api_key(socket) do
    user = Comet.Accounts.get_user_with_profile!(socket.assigns.current_scope.user.id)
    user.profile.api_key
  end

  defp main_asset_url(assets) do
    assets
    |> Enum.find(Enum.at(assets, 0), fn asset -> asset.style == "official" end)
    |> Map.get(:url)
  end
end
