defmodule CometWeb.BacklogLive.Collection do
  alias Comet.Games.Game

  use CometWeb, :live_view

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["backlog", "collection"]}
    >
      <.filters />

      <div class="grid grid-cols-8 gap-4" id="games" phx-update="stream">
        <.game_card
          :for={{dom_id, game} <- @streams.game_list}
          id={dom_id}
          name={game.name}
          status={game.status}
          platform={game.platform}
          cover={game.cover}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :game_list, Game.Query.all())}
  end

  defp filters(assigns) do
    form = to_form(%{"name" => "", "platform" => "", "status" => ""})

    platforms = platforms() |> Map.values()
    statuses = statuses() |> Map.values()

    assigns =
      assign(assigns, %{
        form: form,
        platforms: platforms,
        statuses: statuses
      })

    ~H"""
    <.form class="flex gap-2" id="filter-form" phx-change="filter" for={@form}>
      <.input
        field={@form[:platform]}
        fieldset_class="w-1/8"
        type="select"
        options={@platforms}
        prompt="Platform"
      />
      <.input
        field={@form[:status]}
        fieldset_class="w-1/8"
        type="select"
        options={@statuses}
        prompt="Status"
      />
      <.input field={@form[:name]} fieldset_class="grow" placeholder="Search" autocomplete="off" />
    </.form>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :status, :atom, values: [:completed, :pending, :in_progress], required: true
  attr :platform, :atom, required: true
  attr :cover, :string, required: true

  defp game_card(assigns) do
    ~H"""
    <div class="rounded-md flex flex-col gap-2 game-cover bg-base-300 relative" id={@id}>
      <div class="absolute top-2 left-2 flex gap-1 flex-col">
        <.status_badge status={@status} />
        <.platform_badge platform={@platform} />
      </div>

      <img
        class="aspect-2/3 rounded-tl-md rounded-tl-md"
        src={@cover}
      />

      <span class="font-semibold text-sm truncate px-2 text-center pb-2">{@name}</span>
    </div>
    """
  end

  defp status_badge(assigns = %{status: status}) do
    {label, _} = statuses() |> Map.get(status)

    color =
      case status do
        :completed -> "success"
        :in_progress -> "warning"
        :pending -> "info"
      end

    assigns =
      assign(assigns, %{
        label: label,
        color: color
      })

    ~H"""
    <.badge color={@color}>{@label}</.badge>
    """
  end

  defp platform_badge(assigns = %{platform: platform}) do
    {label, _} = platforms() |> Map.get(platform, "unknown")

    assigns = assign(assigns, :label, label)

    ~H"""
    <.badge color="neutral">{@label}</.badge>
    """
  end

  def platforms() do
    %{
      pc: {"PC", :pc},
      ps1: {"PS1", :ps1},
      ps2: {"PS2", :ps2},
      ps3: {"PS3", :ps3},
      ps4: {"PS4", :ps4},
      ps5: {"PS5", :ps5},
      psp: {"PSP", :psp},
      switch: {"Switch", :switch}
    }
  end

  def statuses() do
    %{
      completed: {"Completed", :completed},
      in_progress: {"In Progress", :in_progress},
      pending: {"Pending", :pending}
    }
  end

  @impl true
  def handle_event("filter", params, socket) do
    socket =
      socket
      |> assign(:form, to_form(params))
      |> stream(:game_list, Game.Query.all(params), reset: true)

    {:noreply, socket}
  end
end
