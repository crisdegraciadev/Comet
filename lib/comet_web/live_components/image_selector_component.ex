defmodule CometWeb.LiveComponents.ImageSelectorComponent do
  use CometWeb, :live_component

  alias Comet.Games.Game.SGDB
  alias Comet.Games.Game

  attr :game, :map, required: true
  attr :backdrop_link, :string
  attr :current_scope, :map, required: true

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{current_scope: current_scope, game: game} = assigns

    api_key = current_scope.user.profile.api_key

    socket =
      socket
      |> assign(:current_scope, current_scope)
      |> assign(:game, game)
      |> assign(:checked, :cover)
      |> assign(:backdrop_link, assigns[:backdrop_link])
      |> assign_async(:covers, fn -> SGDB.get_covers(game.sgdb_id, api_key) end)
      |> assign_async(:heroes, fn -> SGDB.get_heroes(game.sgdb_id, api_key) end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"images-selector-#{@game.id}"}>
      <.game_modal
        id={"change-cover-game-modal-#{@game.id}"}
        backdrop_link={~p"/backlog"}
        game={@game}
      >
        <div class="tabs tabs-border">
          <input
            type="radio"
            name="my_tabs_2"
            class="tab"
            aria-label="Covers"
            checked={@checked == :cover}
          />
          <div class="tab-content border border-base-content/10 bg-base-100 p-2 rounded-box">
            <div class="h-[500px] w-full overflow-y-auto">
              <.async_result :let={covers} assign={@covers}>
                <:loading>
                  <.skeleton width="w-full" height="h-full" />
                </:loading>

                <:failed>
                  <div class="w-full h-full flex flex-col items-center justify-center">
                    <.icon name="lucide-photo" class="size-16" />
                  </div>
                </:failed>

                <div class="grid grid-cols-4 gap-4 pr-2">
                  <img
                    :for={cover <- covers}
                    src={cover.url}
                    class="cursor-pointer rounded"
                    phx-click="update_image"
                    phx-value-url={cover.url}
                    phx-value-field={:cover}
                    phx-target={@myself}
                  />
                </div>
              </.async_result>
            </div>
          </div>

          <input
            type="radio"
            name="my_tabs_2"
            class="tab"
            aria-label="Heros"
            checked={@checked == :hero}
          />

          <div class="tab-content border border-base-content/10 bg-base-100 p-2 rounded-box">
            <div class="h-[500px] w-full overflow-y-auto">
              <.async_result :let={heroes} assign={@heroes}>
                <:loading>
                  <.skeleton width="w-full" height="h-full" />
                </:loading>

                <:failed>
                  <div class="w-full h-full flex flex-col items-center justify-center">
                    <.icon name="lucide-photo" class="size-16" />
                  </div>
                </:failed>

                <div class="grid grid-cols-2 gap-4 pr-2">
                  <img
                    :for={hero <- heroes}
                    src={hero.url}
                    class="cursor-pointer rounded"
                    phx-click="update_image"
                    phx-value-url={hero.url}
                    phx-value-field={:hero}
                    phx-target={@myself}
                  />
                </div>
              </.async_result>
            </div>
          </div>
        </div>

        <div class="mt-4 flex justify-end">
          <.button patch={~p"/backlog/#{@game}/edit"}>Done</.button>
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
