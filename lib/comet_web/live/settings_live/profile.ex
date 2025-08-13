defmodule CometWeb.SettingsLive.Profile do
  use CometWeb, :live_view

  alias Comet.Accounts

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
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
          <:subtitle>Manage your profile username, name and surname</:subtitle>
        </.header>
      </div>

      <.form
        for={@profile_form}
        id="profile_form"
        phx-submit="update_profile"
        phx-change="validate_profile"
      >
        <.input
          field={@profile_form[:username]}
          type="text"
          label="Username"
          required
        />
        <.input
          field={@profile_form[:name]}
          type="text"
          label="Name"
          required
        />
        <.input
          field={@profile_form[:surname]}
          type="text"
          label="Surname"
          required
        />
        <.button variant="primary" phx-disable-with="Saving...">Save Profile</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user |> Comet.Repo.preload(profile: :user)
    profile = user.profile
    changeset = Accounts.change_profile(profile)

    socket =
      socket
      |> assign(:profile, profile)
      |> assign(:profile_form, to_form(changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Accounts.change_profile(profile_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: changeset)}
  end

  def handle_event("update_profile", %{"profile" => profile_params}, socket) do
    case Accounts.update_profile(socket.assigns.profile, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(:profile, profile)
         |> assign(:profile_form, to_form(Accounts.change_profile(profile)))}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert))}
    end
  end
end
