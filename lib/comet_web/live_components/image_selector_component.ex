defmodule CometWeb.LiveComponents.ImageSelectorComponent do
  use CometWeb, :live_component

  alias Comet.Services.SGDB
  alias Comet.Games.Game

  attr :game, :map, required: true
  attr :current_scope, :map, required: true

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{current_scope: current_scope, game: game}, socket) do
    assigns = %{
      covers: SteamGridDB.get_all_covers(game.steamgriddb_id, current_scope.user.profile.api_key),
      heroes: SteamGridDB.get_all_heroes(game.steamgriddb_id, current_scope.user.profile.api_key),
      current_scope: current_scope,
      game: game,
      checked: :cover
    }

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"images-selector-#{@game.id}"}>
      <.game_modal id={"change-cover-game-modal-#{@game.id}"} game={@game}>
        <div class="tabs tabs-border">
          <input
            type="radio"
            name="my_tabs_2"
            class="tab"
            aria-label="Covers"
            checked={@checked == :cover}
          />
          <div class="tab-content border border-base-content/10 bg-base-200 p-2 rounded-box">
            <div class="grid grid-cols-4 gap-4 overflow-y-scroll max-h-[500px] pr-2">
              <img
                :for={img <- @covers}
                src={img}
                class="cursor-pointer rounded"
                phx-click="update_image"
                phx-value-url={img}
                phx-value-field={:cover}
                phx-target={@myself}
              />
            </div>
          </div>

          <input
            type="radio"
            name="my_tabs_2"
            class="tab"
            aria-label="Heros"
            checked={@checked == :hero}
          />
          <div class="tab-content border border-base-content/10 bg-base-200 p-2 rounded-box">
            <div class="grid grid-cols-2 gap-4 overflow-y-scroll max-h-[500px] pr-2">
              <img
                :for={img <- @heroes}
                src={img}
                class="cursor-pointer rounded"
                phx-click="update_image"
                phx-value-url={img}
                phx-value-field={:hero}
                phx-target={@myself}
              />
            </div>
          </div>
        </div>

        <div class="mt-4 flex justify-end">
          <.button variant="error" href={~p"/backlog/collection/#{@game}/edit"}>Back</.button>
        </div>
      </.game_modal>
    </div>
    """
  end

  @impl true
  def handle_event(
        "update_image",
        %{"url" => url, "field" => field},
        %{assigns: %{game: game, current_scope: current_scope}} = socket
      ) do
    {:ok, updated_game} = Game.Command.update(game, current_scope.user, Map.put(%{}, field, url))

    socket = socket |> assign(:game, updated_game) |> assign(:checked, String.to_atom(field))

    send(self(), {:updated_image, updated_game})

    {:noreply, socket}
  end
end
