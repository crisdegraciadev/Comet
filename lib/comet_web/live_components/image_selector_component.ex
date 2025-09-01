defmodule CometWeb.LiveComponents.ImageSelectorComponent do
  use CometWeb, :live_component
  alias Comet.Services.SteamGridDB

  attr :game, :map, required: true
  attr :field, :string, required: true
  attr :api_key, :string, required: true
  attr :show, :boolean, default: false

  @impl true
  def mount(socket) do
    {:ok, assign(socket, images: [])}
  end

  @impl true
  def update(assigns, socket) do
    images =
      if assigns.show do
        load_images(assigns.game, assigns.field, assigns.api_key)
      else
        []
      end

    {:ok, assign(socket, assigns |> Map.put(:images, images))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="image-selector-component">
      <dialog :if={@show} id="image-selector-modal" class="modal modal-open shadow-lg bg-transparent">
        <div
          class="modal-box w-1/2 max-w-[1280px]"
          phx-click-away="close"
          phx-target={@myself}
        >
          <h2 class="font-semibold mb-4">Select an image for {@field}</h2>
          <div class="grid grid-cols-4 gap-4">
            <img :for={img <- @images} src={img} class="cursor-pointer rounded"
              phx-click="select_image"
              phx-value-url={img}
              phx-value-field={@field}
              phx-target={@myself} />
          </div>
          <div class="mt-4 flex justify-end">
            <.button phx-click="close" phx-target={@myself}>Close</.button>
          </div>
        </div>
      </dialog>
    </div>
    """
  end

  @impl true
  def handle_event("select_image", %{"url" => url, "field" => field}, socket) do
    send(self(), {:image_selected, field, url})
    {:noreply, assign(socket, show: false)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, show: false)}
  end

  defp load_images(game, "cover", api_key) do
    game_id = Map.get(game, :steamgriddb_id, game.id)
    SteamGridDB.get_all_covers(game_id, api_key) |> Enum.uniq()
  end

  defp load_images(game, "hero", api_key) do
    game_id = Map.get(game, :steamgriddb_id, game.id)
    SteamGridDB.get_all_heroes(game_id, api_key) |> Enum.uniq()
  end
end
