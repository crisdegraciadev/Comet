defmodule CometWeb.CustomComponents do
  use Phoenix.Component
  use Gettext, backend: CometWeb.Gettext


  import CometWeb.CoreComponents

  alias Comet.Games.Game
  alias Comet.Services.Constants

  attr :id, :string, required: true
  attr :game, Game, required: true
  attr :rest, :global

  slot :actions
  slot :inner_block

  def game_modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal modal-open shadow-lg bg-transparent" {@rest}>
      <div class="game-modal modal-box max-w-[calc(1920px*0.4)] flex flex-col gap-5">
        <div class="relative h-[calc((900px*0.3)+(0.25rem*8))]">
          <img
            src={@game.hero}
            class="h-[calc(620px*0.4)] rounded-md bg-white/30 brightness-50"
          />
          <img
            src={@game.cover}
            class="h-[calc(900px*0.3)] rounded-md absolute top-8 left-6"
          />

          <div class="flex gap-2 ml-[calc(600px*0.3+24px+8px)] mt-2"></div>
        </div>

        <div class="flex flex-col gap-4 mx-6">
          <div class="flex justify-between">
            <h1 class="font-semibold text-4xl">
              {@game.name}
            </h1>

            <div :if={@actions != []} class="flex gap-2">
              {render_slot(@actions)}
            </div>
          </div>

          {render_slot(@inner_block)}
        </div>
      </div>

      <.link class="modal-backdrop" href="/backlog/collection"></.link>
    </dialog>
    """
  end

  def status_badge(assigns = %{status: status}) do
    {label, _} = Constants.statuses() |> Map.get(status)

    color =
      case status do
        :completed -> "success"
        :in_progress -> "warning"
        :pending -> "info"
      end

    assigns = assign(assigns, %{label: label, color: color})

    ~H"""
    <.badge color={@color}>{@label}</.badge>
    """
  end

  def platform_badge(assigns = %{platform: platform}) do
    {label, _} = Constants.platforms() |> Map.get(platform, "unknown")
    assigns = assign(assigns, :label, label)

    ~H"""
    <.badge color="neutral">{@label}</.badge>
    """
  end
end
