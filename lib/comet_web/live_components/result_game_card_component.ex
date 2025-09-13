defmodule CometWeb.LiveComponents.ResultGameCardComponent do
  use CometWeb, :live_component

  alias Comet.Services.SGDB
  alias Comet.Games.Game

  attr :game, :map, required: true
  attr :api_key, :string, required: true

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{api_key: api_key, game: game}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign_async(:covers, fn -> SGDB.get_covers(game.id, api_key) end)
      |> assign_async(:heroes, fn -> SGDB.get_heroes(game.id, api_key) end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="cursor-pointer">
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow bg-base-300 relative aspect-2/3">
        <.async_result :let={covers} assign={@covers}>
          <:loading>
            <.skeleton width="h-full" height="h-full" />
          </:loading>

          <:failed>
            <div class="w-full h-full flex flex-col items-center justify-center">
              <.icon name="hero-photo" class="size-16" />
            </div>
          </:failed>

          <img
            class="rounded-tl-md rounded-tr-md"
            src={main_cover_url(covers)}
            alt={@game.name}
          />
        </.async_result>

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@game.name}</span>
      </div>
    </div>
    """
  end

  defp main_cover_url(covers) do
    covers
    |> Enum.find(Enum.at(covers, 0), fn cover -> cover.style == "official" end)
    |> Map.get(:url)
  end
end
