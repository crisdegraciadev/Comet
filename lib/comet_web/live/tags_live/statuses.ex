defmodule CometWeb.TagsLive.Statuses do
  use CometWeb, :live_view

  alias Comet.Accounts
  alias Comet.Games
  alias Comet.Tags

  import CometWeb.Live.TagsLive.Components

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["tags", "statuses"]}
    >
      <div id="tags-statuses-page" class="flex flex-col gap-4">
        <.card bg="bg-cm-black-200" size="card-sm">
          <div class="flex justify-between items-center">
            <span class="text-lg font-semibold cursor-pointer">Current statuses</span>

            <.button icon="btn-square" variant="btn-secondary" patch={~p"/tags/statuses/new"}>
              <.icon name="lucide-plus" />
            </.button>
          </div>
        </.card>

        <.create_tag_modal
          :if={@live_action == :new}
          user={@user}
          preferences={@preferences}
          changeset={@changeset}
          type={:statuses}
        />

        <.edit_tag_modal
          :if={@live_action == :edit}
          user={@user}
          preferences={@preferences}
          changeset={@changeset}
          type={:statuses}
        />

        <.delete_tag_modal
          :if={@live_action == :delete}
          tag={@status}
          changeset={@changeset}
          type={:statuses}
        />

        <.tags_table type={:statuses} rows={@statuses} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    user = Accounts.get_user_with_profile!(current_scope.user.id)
    preferences = Accounts.get_account_preferences!(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:preferences, preferences)
      |> assign_statuses()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:new] do
    attrs = %{label: "Completed", background: "#314157", foreground: "#f9f9f9"}

    socket = socket |> assign_changetset(%Tags.Status{}, attrs)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:edit, :delete] do
    user = socket.assigns.user
    status = Tags.get_status!(user, id)

    socket = socket |> assign(:status, status) |> assign_changetset(status, %{})

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"status" => status}, socket) do
    user = socket.assigns.user

    case Tags.create_status(user, status) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_statuses()
         |> put_flash(:info, "status created")
         |> push_patch(to: ~p"/tags/statuses", replace: true)}
    end
  end

  @impl true
  def handle_event("update", %{"status" => status_params}, socket) do
    user = socket.assigns.user
    status = socket.assigns.status

    case Tags.update_status(status, user, status_params) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_statuses()
         |> put_flash(:info, "status updated")
         |> push_patch(to: ~p"/tags/statuses", replace: true)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    user = socket.assigns.user
    status = socket.assigns.status

    case Tags.delete_status(status, user) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_statuses()
         |> put_flash(:info, "status deleted")
         |> push_patch(to: ~p"/tags/statuses", replace: true)}
    end
  end

  def handle_event("reload_preview", %{"status" => status}, socket) do
    user = socket.assigns.user
    changeset = Tags.change_status(%Tags.Status{}, user, status)

    socket = socket |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  defp assign_changetset(socket, status, attrs) do
    user = socket.assigns.user
    changeset = Tags.change_status(status, user, attrs)

    socket |> assign(:changeset, changeset)
  end

  defp assign_statuses(socket) do
    user = socket.assigns.user
    status_count = Games.count_games_by_status(user)

    statuses =
      Tags.all_statuses(user)
      |> Enum.map(fn s -> Map.put(s, :count, Map.get(status_count, s.id, 0)) end)
      |> Enum.sort(fn s1, s2 -> s1.count > s2.count end)

    socket |> assign(:statuses, statuses)
  end
end
