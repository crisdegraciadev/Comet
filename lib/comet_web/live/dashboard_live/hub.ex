defmodule CometWeb.DashboardLive.Hub do
  alias Comet.Games.Game

  use CometWeb, :live_view

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["dashboard", "hub"]}
    >
      <h1>Currently playing</h1>
      <div class="grid grid-cols-8 gap-4">
        <.game_card :for={game <- @game_list} id="game.id" game={game} />
      </div>

      <h1>Last completed games</h1>
      <div class="grid grid-cols-8 gap-4">
        <.game_card :for={game <- @game_list} id="game.id" game={game} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :game_list, Game.Query.all())}
  end

  attr :id, :string, required: true
  attr :game, Games.Game

  defp game_card(assigns) do
    ~H"""
    <.link id={@id} href={~p"/backlog/collection/#{@game}"}>
      <div class="rounded-md flex flex-col gap-2 game-cover bg-base-300 relative">
        <img
          class="aspect-2/3 rounded-tl-md rounded-tr-md"
          src={@game.cover}
        />

        <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@game.name}</span>
      </div>
    </.link>
    """
  end
end
