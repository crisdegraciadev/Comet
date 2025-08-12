defmodule CometWeb.SettingsLive.ApiKey do
  use CometWeb, :live_view

  alias Comet.Accounts

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user |> Comet.Repo.preload(profile: :user)
    profile = user.profile
    changeset = Accounts.change_profile(profile)

    socket =
      socket
      |> assign(:profile, profile)
      |> assign(:api_key_form, to_form(changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
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

      <.form for={@api_key_form} id="api_key_form" phx-submit="update_api_key" phx-change="validate_api_key">
        <.input
          field={@api_key_form[:api_key]}
          type="text"
          label="API Key"
        />
        <.button variant="primary" phx-disable-with="Saving...">Save API Key</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate_api_key", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Accounts.change_profile(profile_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, api_key_form: changeset)}
  end

  def handle_event("update_api_key", %{"profile" => profile_params}, socket) do
    case Accounts.update_profile(socket.assigns.profile, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "API Key updated successfully.")
         |> assign(:profile, profile)
         |> assign(:api_key_form, to_form(Accounts.change_profile(profile)))}

      {:error, changeset} ->
        {:noreply, assign(socket, api_key_form: to_form(changeset, action: :insert))}
    end
  end
end
