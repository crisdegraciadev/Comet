defmodule CometWeb.SettingsLive.ApiKey do
  use CometWeb, :live_view

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["settings", "api_key"]}
    >
      <div class="text-center">
        <.header>
          SteamGridDB API Key
          <:subtitle>Manage your SteamGridDB API key</:subtitle>
        </.header>
      </div>
    </Layouts.app>
    """
  end
end
