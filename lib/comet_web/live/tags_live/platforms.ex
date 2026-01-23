defmodule CometWeb.TagsLive.Platforms do
  use CometWeb, :live_view

  alias Comet.Accounts.Preferences
  alias Comet.Games.Game

  import CometWeb.Live.TagsLive.Components

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["tags", "platforms"]}
    >
      <div id="tags-platforms-page" class="flex flex-col gap-4">
        <.collapse id="platform-tag-manager-collapse" title="Platform manager">
          <div class="flex justify-between gap-4 w-full">
            <.demo_game_list games={@games} preferences={@preferences} />

            <.create_tag_form tag={@tag} />
          </div>
        </.collapse>

        <div class="flex flex-1 items-start">
          <div class="w-full rounded-box border border-base-300 bg-base-200">
            <.table
              id="platform-labels-table"
              rows={[
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true},
                %{label: "PS1", background: "FFFFFF", foreground: "000000", enabled: true}
              ]}
            >
              <:col label="#">
                <input type="checkbox" checked="checked" class="checkbox checkbox-primary" />
              </:col>
              <:col :let={row} label="Result">
                <.badge color="badge-success">{row.label}</.badge>
              </:col>
              <:col :let={row} label="Label">{row.label}</:col>
              <:col :let={row} label="Background">
                <div class="flex gap-1 items-center">
                  <.badge size="badge-sm" color="badge-success" />
                  <span>{row.background}</span>
                </div>
              </:col>
              <:col :let={row} label="Foreground">
                <div class="flex gap-1 items-center">
                  <.badge size="badge-sm" color="badge-success" />
                  <span>{row.foreground}</span>
                </div>
              </:col>
              <:col label="State">
                <.badge>Enabled</.badge>
              </:col>
              <:col label="Games">
                54
              </:col>
              <:action>
                <.button icon="btn-square">
                  <.icon name="lucide-pencil" />
                </.button>
              </:action>
              <:action>
                <.button icon="btn-square" variant="btn-error">
                  <.icon name="lucide-trash" />
                </.button>
              </:action>
            </.table>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    user = Comet.Repo.preload(user, :profile)
    preferences = Preferences.Query.get!(user)

    games = Game.Query.random(5)

    tag = %{value: "PSX", background: "", foreground: ""}

    socket =
      socket |> assign(:preferences, preferences) |> assign(:games, games) |> assign(:tag, tag)

    {:ok, socket}
  end

  @impl true
  def handle_event("reload_demo", _params, socket) do
    games = Game.Query.random(5)
    socket = socket |> assign(:games, games)

    {:noreply, socket}
  end
end
