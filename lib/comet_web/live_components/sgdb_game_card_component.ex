defmodule CometWeb.LiveComponents.SGDBGameCardComponent do
  use CometWeb, :live_component

  alias Comet.Games.Game.SGDB

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
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-cm-black-200 border border-cm-black-300 aspect-2/3">
        <.async_result :let={covers} assign={@covers}>
          <:loading>
            <.skeleton width="h-full" height="h-full" />
          </:loading>

          <:failed>
            <.missing_cover />
          </:failed>

          <.missing_cover :if={covers == []} />

          <img
            :if={covers != []}
            class="rounded-tl-md rounded-tr-md"
            src={CometWeb.Utils.Assets.main_asset_url(covers)}
            alt={@sgdb_game.name}
          />
        </.async_result>

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@sgdb_game.name}</span>
      </div>
    </div>
    """
  end

  defp missing_cover(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-col items-center justify-center">
      <.icon name="lucide-file-image" size="size-16" />
    </div>
    """
  end
end
