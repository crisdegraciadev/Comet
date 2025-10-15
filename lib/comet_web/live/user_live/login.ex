defmodule CometWeb.UserLive.Login do
  use CometWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.login flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <h1 class="font-bold text-2xl">Login</h1>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <div class="flex flex-col gap-2 mt-4">
            <.button class="w-full" name={@form[:remember_me].name} value="true">
              Log in
            </.button>
            <.divider label="Don't you have an account?" />
            <.button class="w-full" navigate={~p"/users/register"}>
              Register
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.login>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
