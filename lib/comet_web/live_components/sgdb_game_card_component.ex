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
      |> assign_async(:heroes, fn -> SGDB.get_heroes(sgdb_game.id, api_key) end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="cursor-pointer">
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-cm-black-200 border border-cm-grey aspect-96/31">
        <.async_result :let={heroes} assign={@heroes}>
          <:loading>
            <.skeleton width="h-full" height="h-full" />
          </:loading>

          <:failed>
            <.missing_hero />
          </:failed>

          <.missing_hero :if={heroes == []} />

          <img
            :if={heroes != []}
            class="rounded-tl-md rounded-tr-md brightness-50"
            src={Game.Utils.main_asset_url(heroes)}
            alt={@sgdb_game.name}
          />
        </.async_result>

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@sgdb_game.name}</span>
      </div>
    </div>
    """
  end

  defp missing_hero(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-col items-center justify-center">
      <.icon name="lucide-file-image" size="size-16" />
    </div>
    """
  end
end
