defmodule CometWeb.Live.BrowserLive.Components do
  use Phoenix.Component
  use CometWeb, :html

  alias Comet.Games.Game
  alias Comet.Services.Constants
  alias CometWeb.LiveComponents.SGDBGameCardComponent

  attr :api_key, :string, default: nil
  attr :query, :string, default: ""

  def search_form(%{api_key: nil} = assigns) do
    ~H"""
    <.alert :if={!@api_key} color="alert-warning">
      <.icon name="lucide-info" />
      <span>
        You need to configure your SteamGridDB API key in
        <.link href={~p"/settings/api_key"} class="link">Settings</.link>
        to search for games.
      </span>
    </.alert>
    """
  end

  def search_form(assigns) do
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
    </div>
    """
  end

  def search_results(%{results: nil} = assigns) do
    ~H"""
    <div class="text-center py-8 text-base-content/70">
      Type a search term to find your games.
    </div>
    """
  end

  def search_results(%{results: []} = assigns) do
    ~H"""
    <div class="text-center py-8 text-base-content/70">
      No games found. Try a different search term.
    </div>
    """
  end

  def search_results(assigns) do
    ~H"""
    <div class="grid grid-cols-8 gap-4">
      <.link
        :for={sgdb_game <- @results}
        navigate={~p"/browser/#{sgdb_game.id}/new?query=#{@query}"}
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

  def add_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)

    platforms = Constants.platforms(:values)

    {_, default_platform} =
      Enum.find(platforms, Enum.at(platforms, 0), fn {_, value} -> value == :pc end)

    statuses = Constants.statuses(:values)

    {_, default_status} =
      Enum.find(statuses, Enum.at(statuses, 0), fn {_, value} -> value == :pending end)

    assigns =
      assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, platforms)
      |> assign(:default_platform, default_platform)
      |> assign(:statuses, statuses)
      |> assign(:default_status, default_status)

    ~H"""
    <.game_modal
      id={"edit-sgdb-game-modal-#{@sgdb_game.id}"}
      game={@sgdb_game}
      backdrop_link={~p"/browser?query=#{@query}"}
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
            value={@default_platform}
            fieldset_class="grow"
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={@statuses}
            value={@default_status}
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
          <.button variant="btn-error" patch={~p"/browser?query=#{@query}"}>Cancel</.button>
        </div>
      </.form>
    </.game_modal>
    """
  end
end
