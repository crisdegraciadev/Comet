defmodule CometWeb.BrowserLive.Collection do
  use CometWeb, :live_view

  alias Comet.Games.Game
  alias Comet.Services.SGDB
  alias Comet.Services.Constants
  alias CometWeb.LiveComponents.SGDBGameCardComponent

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
      <.search_results api_key={@api_key} results={assigns[:results]} query={assigns[:query]} />

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
    {:noreply, push_navigate(socket, to: ~p"/browser/collection?query=#{query}", replace: true)}
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
         |> push_navigate(to: ~p"/browser/collection?query=#{query}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Error adding game to backlog")}
    end
  end

  attr :api_key, :string, default: nil
  attr :query, :string, default: ""

  defp search_form(assigns) do
    assigns = assign(assigns, :form, to_form(%{"query" => assigns.query}))

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
          <.icon name="lucide-search" /> Search
        </.button>
      </.form>

      <.alert :if={!@api_key} color="warning">
        <.icon name="lucide-info" />
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
      Type a search term to find your games.
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
    ~H"""
    <div class="grid grid-cols-3 gap-4">
      <.link
        :for={sgdb_game <- @results}
        navigate={~p"/browser/collection/#{sgdb_game.id}/new?query=#{@query}"}
      >
        <.live_component
          module={SGDBGameCardComponent}
          id={sgdb_game.id}
          sgdb_game={sgdb_game}
          api_key={@api_key}
        />
      </.link>
    </div>
    """
  end

  attr :sgdb_game, :map, required: true
  attr :query, :string, required: true
  attr :current_scope, :map, required: true

  defp add_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)

    platforms = Constants.platforms(:values)

    {_, defaultPlatform} =
      Enum.find(platforms, Enum.at(platforms, 0), fn {_, value} -> value == :pc end)

    statuses = Constants.statuses(:values)

    {_, defaultStatus} =
      Enum.find(statuses, Enum.at(statuses, 0), fn {_, value} -> value == :pending end)

    assigns =
      assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, platforms)
      |> assign(:defaultPlatform, defaultPlatform)
      |> assign(:statuses, statuses)
      |> assign(:defaultStatus, defaultStatus)

    ~H"""
    <.game_modal
      id={"edit-sgdb-game-modal-#{@sgdb_game.id}"}
      game={@sgdb_game}
      backdrop_link={~p"/browser/collection?query=#{@query}"}
    >
      <.form
        class="flex flex-col h-full justify-between"
        id={"new-game-form-#{@sgdb_game.id}"}
        phx-submit="save"
        for={@form}
      >
        <.input field={@form[:name]} label="Name" value={@sgdb_game.name} autocomplete="off" />

        <div class="flex gap-2">
          <.input
            field={@form[:platform]}
            type="select"
            label="Platform"
            options={@platforms}
            value={@defaultPlatform}
            fieldset_class="grow"
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={@statuses}
            value={@defaultStatus}
            fieldset_class="grow"
          />
        </div>
        <.input
          field={@form[:sgdb_id]}
          value={@sgdb_game.id}
          autocomplete="off"
          fieldset_class="hidden"
        />
        <.input
          field={@form[:cover]}
          value={@sgdb_game.cover}
          fieldset_class="hidden"
        />
        <.input
          field={@form[:hero]}
          value={@sgdb_game.hero}
          fieldset_class="grow hidden"
        />
        <div class="flex justify-end gap-2 mt-4">
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
          <!-- <.button variant="error" href={~p"/backlog/collection/#{@game.id}"}>Cancel</.button> -->
        </div>
      </.form>
    </.game_modal>
    """
  end

  defp assign_game(%{assigns: %{api_key: api_key}} = socket, id) do
    {:ok, %{game: %{id: id, name: name}}} = SGDB.get_game(id, api_key)
    {:ok, %{covers: covers}} = SGDB.get_covers(id, api_key)
    {:ok, %{heroes: heroes}} = SGDB.get_heroes(id, api_key)

    sgdb_game = %{
      id: id,
      name: name,
      cover: Game.Utils.main_asset_url(covers),
      hero: Game.Utils.main_asset_url(heroes)
    }

    assign(socket, :sgdb_game, sgdb_game)
  end

  defp assign_results(%{assigns: %{api_key: api_key, query: query}} = socket) do
    case SGDB.search(query, api_key) do
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
