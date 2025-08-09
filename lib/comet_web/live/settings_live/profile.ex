defmodule CometWeb.SettingsLive.Profile do
  use CometWeb, :live_view

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["settings", "profile"]}
    >
      <div class="text-center">
        <.header>
          Profile Settings
          <:subtitle>Manage your profile name surname and avatar settings</:subtitle>
        </.header>
      </div>
    </Layouts.app>
    """
  end
end
