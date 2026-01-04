defmodule CometWeb.BacklogLive.Collection do
  use CometWeb, :live_view

  alias Comet.Accounts.Preferences
  alias Comet.Games
  alias Comet.Games.Game
  alias Comet.Services.Constants
  alias CometWeb.LiveComponents.ImageSelectorComponent

  on_mount {CometWeb.UserAuth, :require_sudo_mode}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_module={["backlog", "collection"]}
    >
      <div id="backlog-page" class="flex flex-col gap-2" phx-hook="PreserveScroll">
        <div class="flex justify-between gap-2">
          <.filters />
        </div>

        <.game_list streams={@streams} preferences={@preferences} />

        <.show_game_modal :if={@live_action == :show} game={@game} />
        <.delete_game_modal :if={@live_action == :delete} game={@game} />
        <.edit_game_modal :if={@live_action == :edit} game={@game} current_scope={@current_scope} />
        <.display_options_modal :if={@live_action == :display_options} preferences={@preferences} />

        <.live_component
          :if={@live_action == :images_edit}
          module={ImageSelectorComponent}
          id={"images-selector-#{@game.id}"}
          game={@game}
          current_scope={@current_scope}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket) do
    user = Comet.Repo.preload(user, :profile)
    preferences = Preferences.Query.get!(user)

    socket =
      socket
      |> assign(:current_scope, %{user: user})
      |> assign(:preferences, preferences)
      |> stream(:game_list, Game.Query.all(user))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, %{assigns: %{live_action: live_action}} = socket)
      when live_action in [:list, :display_options] do
    {:noreply, assign(socket, :game, nil)}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _url,
        %{assigns: %{live_action: live_action, current_scope: %{user: user}}} = socket
      )
      when live_action in [:show, :edit, :delete, :images_edit] do
    game = Game.Query.get!(user, String.to_integer(id))

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("filter", params, %{assigns: %{current_scope: %{user: user}}} = socket) do
    socket =
      socket
      |> assign(:form, to_form(params))
      |> stream(:game_list, Game.Query.all(user, params), reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change_display",
        params,
        %{assigns: %{preferences: preferences, current_scope: %{user: user}}} = socket
      ) do
    {:ok, updated_preferences} = Preferences.Command.update(preferences, user, params)

    socket =
      socket
      |> assign(:preferences, updated_preferences)
      |> stream(:game_list, Game.Query.all(user))

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_scope: %{user: user}}} = socket) do
    game = Game.Query.get!(user, id)
    Game.Command.delete!(game)

    socket =
      socket
      |> stream_delete(:game_list, game)
      |> put_flash(:info, "Game deleted")
      |> push_patch(to: ~p"/backlog/collection", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "update",
        %{"game" => game_params},
        %{assigns: %{game: game, current_scope: %{user: user}}} = socket
      ) do
    {:ok, updated_game} = Game.Command.update(game, user, game_params)

    socket =
      socket
      |> assign(:game, updated_game)
      |> stream_insert(:game_list, updated_game)
      |> put_flash(:info, "Game updated!")
      |> push_patch(to: ~p"/backlog/collection/#{updated_game.id}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:updated_image, updated_game}, socket) do
    {:noreply, socket |> stream_insert(:game_list, updated_game)}
  end

  defp filters(assigns) do
    form =
      to_form(%{
        "name" => "",
        "platform" => "",
        "status" => "",
        "group" => "",
        "sort" => "status",
        "order" => "asc"
      })

    assigns =
      assign(assigns, %{
        form: form,
        platforms: Constants.platforms(:values),
        statuses: Constants.statuses(:values),
        groups: Constants.groups(:values),
        sorts: Constants.sorts(:values),
        orders: Constants.orders(:values)
      })

    ~H"""
    <.form class="flex justify-between w-full" id="filter-form" phx-change="filter" for={@form}>
      <div class="flex gap-2">
        <.input field={@form[:name]} fieldset_class="grow" placeholder="Search" autocomplete="off" />

        <.input
          field={@form[:platform]}
          type="select"
          options={@platforms}
          prompt="Platform"
        />
        <.input
          field={@form[:status]}
          type="select"
          options={@statuses}
          prompt="Status"
        />
      </div>
      <div class="flex gap-2">
        <!-- <.input -->
        <!--   field={@form[:group]} -->
        <!--   label_wrapper_class="select" -->
        <!--   label_span_class="!mb-0" -->
        <!--   type="select" -->
        <!--   label="Group" -->
        <!--   options={@groups} -->
        <!--   prompt="None" -->
        <!-- /> -->

        <.input
          field={@form[:sort]}
          label_wrapper_class="select"
          label_span_class="!mb-0"
          type="select"
          label="Sort"
          options={@sorts}
        />

        <.input
          field={@form[:order]}
          label_wrapper_class="select"
          label_span_class="!mb-0"
          type="select"
          label="Order"
          options={@orders}
        />
      </div>
    </.form>

    <.button
      variant="btn-secondary"
      icon="btn-square"
      patch={~p"/backlog/collection/display/options"}
    >
      <.icon name="lucide-layout-dashboard" />
    </.button>
    """
  end

  attr :streams, :any, required: true
  attr :preferences, Preferences, required: true

  defp game_list(assigns) do
    grid_cols =
      case assigns.preferences.cols do
        2 -> "grid-cols-2"
        3 -> "grid-cols-3"
        4 -> "grid-cols-4"
        5 -> "grid-cols-5"
        6 -> "grid-cols-6"
        7 -> "grid-cols-7"
        8 -> "grid-cols-8"
        9 -> "grid-cols-9"
        10 -> "grid-cols-10"
        11 -> "grid-cols-11"
        12 -> "grid-cols-12"
      end

    assigns = assigns |> assign(:cols, grid_cols)

    ~H"""
    <div class={["grid", @cols, "gap-4"]} id="games" phx-update="stream">
      <.game_card
        :for={{dom_id, game} <- @streams.game_list}
        id={dom_id}
        game={game}
        preferences={@preferences}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :game, Games.Game
  attr :preferences, Preferences, required: true

  defp game_card(%{preferences: %{assets: :cover}} = assigns) do
    ~H"""
    <.link id={@id} patch={~p"/backlog/collection/#{@game}"}>
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow border border-cm-black-300 bg-cm-black-200 relative">
        <div class="absolute top-2 left-2 flex gap-1 flex-col z-1">
          <.status_badge status={@game.status} />
          <.platform_badge platform={@game.platform} />
        </div>
        <img class="aspect-2/3 rounded-tl-md rounded-tr-md" src={@game.cover} />
        <span class={[
          "font-semibold text-sm truncate px-2 text-center pb-2",
          !@preferences.show_name && "!hidden"
        ]}>
          {@game.name}
        </span>
      </div>
    </.link>
    """
  end

  defp game_card(%{preferences: %{assets: :hero}} = assigns) do
    ~H"""
    <.link id={@id} patch={~p"/backlog/collection/#{@game}"}>
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow border border-cm-black-300 bg-cm-black-200 relative aspect-96/31">
        <div class="absolute top-2 left-2 flex gap-1 flex-col z-1">
          <.status_badge status={@game.status} />
          <.platform_badge platform={@game.platform} />
        </div>

        <div
          :if={@game.hero == nil}
          class="w-full h-full flex flex-col items-center justify-center bg-cm-black-100"
        >
        </div>

        <img
          class="rounded-tl-md rounded-tr-md"
          src={@game.hero}
        />
        <span class={[
          "font-semibold text-sm truncate px-2 text-center pb-2",
          !@preferences.show_name && "!hidden"
        ]}>
          {@game.name}
        </span>
      </div>
    </.link>
    """
  end

  attr :game, Games.Game

  defp show_game_modal(assigns) do
    ~H"""
    <.game_modal
      id={"show-game-modal-#{@game.id}"}
      game={@game}
      backdrop_link={~p"/backlog/collection"}
    >
      <:actions>
        <.button patch={~p"/backlog/collection/#{@game}/edit"}>
          <.icon name="lucide-pencil" /> Edit
        </.button>
        <.button variant="btn-error" patch={~p"/backlog/collection/#{@game}/delete"}>
          <.icon name="lucide-trash" /> Delete
        </.button>
      </:actions>

      <div class="flex flex-col gap-2 rounded-box bg-cm-black-100 border border-cm-black-300  p-4">
        <div class="grid grid-cols-2">
          <span><.icon name="lucide-circle-stack" class="mr-2 size-4" /> Status</span>
          <.status_badge status={@game.status} />
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="lucide-computer-desktop" class="mr-2 size-4" />Platform</span>
          <.platform_badge platform={@game.platform} />
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="lucide-calendar" class="mr-2 size-4" />Purchased</span>
          <span>15 de Enero, 2018</span>
        </div>
        <div class="grid grid-cols-2">
          <span><.icon name="lucide-calendar-days" class="mr-2 size-4" />Completition</span>
          <span>10 de Junio, 2020</span>
        </div>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game

  defp delete_game_modal(assigns) do
    ~H"""
    <.game_modal
      id={"delete-game-modal-#{@game.id}"}
      game={@game}
      backdrop_link={~p"/backlog/collection"}
    >
      <div class="flex flex-col gap-2">
        <p>
          You are about to <span class="font-bold">delete</span>
          the following game from your collection.
          <span class="font-bold">This action can't be undone </span>
          and you will lose all your data related with the game.
        </p>
      </div>
      <div class="flex justify-end w-full gap-2">
        <.button phx-click="delete" phx-value-id={@game.id}>Confirm</.button>
        <.button variant="btn-error" patch={~p"/backlog/collection/#{@game.id}"}>Cancel</.button>
      </div>
    </.game_modal>
    """
  end

  attr :game, Games.Game
  attr :current_scope, :map, required: true

  defp edit_game_modal(assigns) do
    changeset = Game.Command.change(%Game{}, assigns.current_scope.user)

    assigns =
      assigns
      |> assign(:form, to_form(changeset))
      |> assign(:platforms, Constants.platforms(:values))
      |> assign(:statuses, Constants.statuses(:values))

    ~H"""
    <.game_modal
      id={"edit-game-modal-#{@game.id}"}
      game={@game}
      backdrop_link={~p"/backlog/collection"}
    >
      <:actions>
        <.button variant="btn-secondary" patch={~p"/backlog/collection/#{@game.id}/images/edit"}>
          <.icon name="lucide-file-image" /> Images
        </.button>
      </:actions>

      <.form
        class="flex flex-col h-full justify-between"
        id={"edit-game-form-#{@game.id}"}
        phx-submit="update"
        for={@form}
      >
        <.input field={@form[:name]} label="Name" value={@game.name} autocomplete="off" />

        <div class="flex gap-2">
          <.input
            field={@form[:platform]}
            type="select"
            label="Platform"
            options={@platforms}
            value={@game.platform}
            fieldset_class="grow"
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={@statuses}
            value={@game.status}
            fieldset_class="grow"
          />
        </div>
        <.input
          field={@form[:cover]}
          label="Cover URL"
          placeholder="Cover URL"
          value={@game.cover}
          autocomplete="off"
          fieldset_class="grow"
        />
        <.input
          field={@form[:hero]}
          label="Hero URL"
          placeholder="Hero URL"
          value={@game.hero}
          autocomplete="off"
          fieldset_class="grow"
        />
        <div class="flex justify-end gap-2 mt-4">
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
          <.button variant="btn-error" patch={~p"/backlog/collection/#{@game.id}"}>
            Cancel
          </.button>
        </div>
      </.form>
    </.game_modal>
    """
  end

  defp display_options_modal(assigns) do
    %{preferences: preferences} = assigns

    form =
      to_form(%{
        "cols" => preferences.cols,
        "show_name" => preferences.show_name,
        "assets" => preferences.assets
      })

    cols = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    assets = [{"Cover", :cover}, {"Hero", :hero}]
    show_name = [{"Yes", true}, {"No", false}]

    assigns =
      assign(assigns, %{
        form: form,
        cols: cols,
        assets: assets,
        show_name: show_name
      })

    ~H"""
    <.modal id="display-options-modal" backdrop_link={~p"/backlog/collection"}>
      <:header>
        <h2 class="font-semibold text-2xl">Display Options</h2>
      </:header>
      <:body>
        <.form
          class="flex flex-col"
          id="display-options-form"
          phx-change="change_display"
          for={@form}
        >
          <.input
            field={@form[:cols]}
            type="select"
            label="Columns"
            options={@cols}
          />

          <.input
            field={@form[:assets]}
            type="select"
            label="Asset"
            options={@assets}
          />

          <.input
            field={@form[:show_name]}
            type="select"
            label="Name"
            options={@show_name}
          />
        </.form>
      </:body>
      <:footer>
        <.button patch={~p"/backlog/collection"}>Done</.button>
      </:footer>
    </.modal>
    """
  end
end
