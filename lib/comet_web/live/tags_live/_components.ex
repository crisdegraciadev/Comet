defmodule CometWeb.Live.TagsLive.Components do
  use Phoenix.Component
  use CometWeb, :html

  alias Comet.Accounts.Preferences

  attr :games, :list, required: true
  attr :preferences, Preferences, required: true

  def demo_game_list(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-4 flex-1">
      <.game_card
        :for={game <- @games}
        id="game-card-demo"
        game={game}
        preferences={@preferences}
        path_link={~p"/backlog"}
      />
    </div>
    """
  end

  attr :tag, :any, required: true

  def create_tag_form(assigns) do
    ~H"""
    <.card>
      <div class="flex flex-col justify-between h-full">
        <div class="flex justify-center">
          <.badge>{@tag.value}</.badge>
        </div>

        <div class="flex flex-col gap-2">
          <label class="input">
            <span class="label">Tag</span>
            <input type="text" value={@tag.value} />
          </label>

          <label class="color-picker">
            <span class="label">Foreground</span>
            <div class="picker-wrapper">
              <span id="platforms-color-picker-input" phx-hook="ColorPicker" />
            </div>
          </label>

          <label class="color-picker">
            <span class="label">Background</span>
            <div class="picker-wrapper">
              <span id="platforms-color-picker-input" phx-hook="ColorPicker" />
            </div>
          </label>

          <div class="flex gap-2">
            <.button variant="btn-secondary" class="w-full" phx-click="reload_demo">
              <.icon name="lucide-refresh-ccw" /> Reload demo
            </.button>

            <.button>
              <.icon name="lucide-plus" /> Create
            </.button>
          </div>
        </div>
      </div>
    </.card>
    """
  end
end
