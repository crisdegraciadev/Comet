defmodule CometWeb.TagsLive.Platforms do
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
      current_module={["tags", "platforms"]}
    >
      <div id="tags-platforms-page" class="flex flex-col gap-4">
        <.card bg="bg-cm-black-200" size="card-sm">
          <div class="flex justify-between items-center">
            <span class="text-lg font-semibold cursor-pointer">Current platforms</span>

            <.button icon="btn-square" variant="btn-secondary" patch={~p"/tags/platforms/new"}>
              <.icon name="lucide-plus" />
            </.button>
          </div>
        </.card>

        <.create_tag_modal
          :if={@live_action == :new}
          user={@user}
          preferences={@preferences}
          changeset={@changeset}
          type={:platforms}
        />

        <.edit_tag_modal
          :if={@live_action == :edit}
          user={@user}
          preferences={@preferences}
          changeset={@changeset}
          type={:platforms}
        />

        <.delete_tag_modal
          :if={@live_action == :delete}
          tag={@platform}
          changeset={@changeset}
          type={:platforms}
        />

        <.tags_table type={:platforms} rows={@platforms} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    user = Accounts.get_user_with_profile!(current_scope.user.id)
    preferences = Accounts.Preferences.Query.get!(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:preferences, preferences)
      |> assign_platforms()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:new] do
    attrs = %{label: "PSX", background: "#314157", foreground: "#f9f9f9"}

    socket = socket |> assign_changetset(%Tags.Platform{}, attrs)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:edit, :delete] do
    user = socket.assigns.user
    platform = Tags.get_platform!(user, id)

    socket = socket |> assign(:platform, platform) |> assign_changetset(platform, %{})

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"platform" => platform}, socket) do
    user = socket.assigns.user

    case Tags.create_platform(user, platform) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_platforms()
         |> put_flash(:info, "Platform created")
         |> push_patch(to: ~p"/tags/platforms", replace: true)}
    end
  end

  @impl true
  def handle_event("update", %{"platform" => platform_params}, socket) do
    user = socket.assigns.user
    platform = socket.assigns.platform

    case Tags.update_platform(platform, user, platform_params) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_platforms()
         |> put_flash(:info, "Platform updated")
         |> push_patch(to: ~p"/tags/platforms", replace: true)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    user = socket.assigns.user
    platform = socket.assigns.platform

    case Tags.delete_platform(platform, user) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_platforms()
         |> put_flash(:info, "Platform deleted")
         |> push_patch(to: ~p"/tags/platforms", replace: true)}
    end
  end

  def handle_event("reload_preview", %{"platform" => platform}, socket) do
    user = socket.assigns.user
    changeset = Tags.change_platform(%Tags.Platform{}, user, platform)

    socket = socket |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  defp assign_changetset(socket, platform, attrs) do
    user = socket.assigns.user
    changeset = Tags.change_platform(platform, user, attrs)

    socket |> assign(:changeset, changeset)
  end

  defp assign_platforms(socket) do
    user = socket.assigns.user
    platform_count = Games.Game.Query.count_by_platform(user)

    platforms =
      Tags.all_platforms(user)
      |> Enum.map(fn p -> Map.put(p, :count, Map.get(platform_count, p.id, 0)) end)
      |> Enum.sort(fn p1, p2 -> p1.count > p2.count end)

    socket |> assign(:platforms, platforms)
  end
end
