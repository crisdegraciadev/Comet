defmodule CometWeb.LiveComponents.SGDBGameCardComponent do
  use CometWeb, :live_component

  alias Comet.Games.Game
  alias Comet.Services.SGDB

  attr :sgdb_game, :map, required: true
  attr :api_key, :string, required: true

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{api_key: api_key, sgdb_game: sgdb_game}, socket) do
    socket =
      socket
      |> assign(:sgdb_game, sgdb_game)
      |> assign_async(:covers, fn -> SGDB.get_covers(sgdb_game.id, api_key) end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="cursor-pointer">
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-base-300 aspect-2/3">
        <.async_result :let={covers} assign={@covers}>
          <:loading>
            <.skeleton width="h-full" height="h-full" />
          </:loading>

          <:failed>
            <div class="w-full h-full flex flex-col items-center justify-center">
              <.icon name="lucide-photo" class="size-16" />
            </div>
          </:failed>

          <img
            class="rounded-tl-md rounded-tr-md"
            src={Game.Utils.main_asset_url(covers)}
            alt={@sgdb_game.name}
          />
        </.async_result>

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@sgdb_game.name}</span>
      </div>
    </div>
    """
  end
end
