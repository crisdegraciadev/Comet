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
        />

        <.delete_tag_modal :if={@live_action == :delete} tag={@tag} />

        <.tags_table type={:platforms} rows={@tags} />
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
      |> assign_tags()

    {:ok, socket}
  end

  @impl true
  def handle_params(
        _params,
        _url,
        %{assigns: %{live_action: live_action}} = socket
      )
      when live_action in [:new, :edit] do
    socket = socket |> assign_changetset()

    {:noreply, socket}
  end

  def handle_params(
        %{"id" => id},
        _url,
        %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket
      )
      when live_action in [:delete, :show] do
    tag = Tags.get_platform!(user, id)

    socket = socket |> assign(:tag, tag)

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "create",
        %{"platform" => platform},
        %{assigns: %{current_scope: %{user: user}}} = socket
      ) do
    case Tags.create_platform(user, platform) do
      {:error, changeset} ->
        {:noreply, socket |> assign(:changeset, changeset)}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign_tags()
         |> put_flash(:info, "Platform created")
         |> push_patch(to: ~p"/tags/platforms", replace: true)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    platform = Tags.get_platform!(user, id)
    Tags.delete_platform!(platform)

    socket =
      socket
      |> assign_tags()
      |> put_flash(:info, "Platform deleted")
      |> push_patch(to: ~p"/tags/platforms", replace: true)

    {:noreply, socket}
  end

  def handle_event(
        "reload_preview",
        %{"platform" => platform},
        %{assigns: %{current_scope: %{user: user}}} = socket
      ) do
    changeset = Tags.change_platform(%Tags.Platform{}, user, platform)
    socket = socket |> assign(:changeset, changeset)

    {:noreply, socket}
  end

  defp assign_changetset(%{assigns: %{changeset: _}} = socket), do: socket

  defp assign_changetset(socket) do
    user = socket.assigns.user

    changeset =
      Tags.change_platform(%Tags.Platform{}, user, %{
        label: "PSX",
        background: "#314157",
        foreground: "#F9F9F9"
      })

    socket |> assign(:changeset, changeset)
  end

  defp assign_tags(socket) do
    user = socket.assigns.user
    platform_count = Games.Game.Query.count_by_platform(user)

    tags =
      Tags.all_platforms(user)
      |> Enum.map(fn t -> Map.put(t, :count, Map.get(platform_count, t.id, 0)) end)

    socket |> assign(:tags, tags)
  end
end
