defmodule CometWeb.TagsLive.Statuses do
  use CometWeb, :live_view

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["tags", "statuses"]}
    >
      <div id="backlog-page" class="flex flex-col gap-4" phx-hook="PreserveScroll">
        Statuses
      </div>
    </Layouts.app>
    """
  end
end
