defmodule CometWeb.Live.TagsLive.Components do
  use Phoenix.Component
  use CometWeb, :html

  alias Comet.Accounts

  attr :games, :list, required: true
  attr :preferences, Accounts.Preferences, required: true

  defp demo_game_list(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-4 flex-1">
      <.game_card
        :for={game <- @games}
        id="game-card-demo"
        game={game}
        preferences={@preferences}
        path_link={~p"/backlog"}
      />
    </div>
    """
  end

  attr :user, Accounts.User, required: true
  attr :preferences, Accounts.Preferences, required: true
  attr :changeset, :any, required: true

  def create_tag_modal(assigns) do
    assigns = assigns |> assign(:form, to_form(assigns.changeset))

    values = assigns.changeset.changes

    preview_tag = %{
      label: Map.get(values, :label, ""),
      background: Map.get(values, :background, ""),
      foreground: Map.get(values, :foreground, "")
    }

    assigns = assigns |> assign(:preview_tag, preview_tag)

    ~H"""
    <.modal id="create-tag-modal" backdrop_link={~p"/tags/platforms"}>
      <:header title="Create tag" />
      <:body>
        <div class="flex flex-col gap-4">
          <div class="flex justify-center gap-2">
            <.tag_badge tag={@preview_tag} />
          </div>

          <.form
            class="flex flex-col gap-2 h-full justify-between"
            id="create-tag-form"
            phx-submit="create"
            phx-change="reload_preview"
            for={@form}
          >
            <.input field={@form[:label]} label="Label" required autocomplete="off" />
            <.input
              type="color"
              field={@form[:background]}
              label="Background"
              required
              autocomplete="off"
            />
            <.input
              type="color"
              field={@form[:foreground]}
              label="Foreground"
              required
              autocomplete="off"
            />
          </.form>
        </div>
      </:body>
      <:footer>
        <.button variant="btn-primary" form="create-tag-form">Create</.button>
        <.button variant="btn-error">Cancel</.button>
      </:footer>
    </.modal>
    """
  end

  attr :tag, :any, required: true

  def delete_tag_modal(assigns) do
    ~H"""
    <.modal id="create-tag-modal" backdrop_link={~p"/tags/platforms"}>
      <:header title="Delete tag" />
      <:body>
        <div class="flex flex-col gap-4">
          <div class="flex justify-center gap-2">
            <.tag_badge tag={@tag} />
          </div>
          <p>
            You are about to <span class="font-bold">delete</span>
            the following tag from your account. To perform this action the tag should not be attached to any game.
            <span class="font-bold">This action can't be undone. </span>
          </p>
        </div>
      </:body>
      <:footer>
        <.button phx-click="delete" phx-value-id={@tag.id}>Confirm</.button>
        <.button variant="btn-error" patch={~p"/tags/platforms"}>Cancel</.button>
      </:footer>
    </.modal>
    """
  end

  attr :type, :atom, values: ~w(platforms statuses)a
  attr :rows, :list, required: true

  def tags_table(assigns) do
    ~H"""
    <div class="w-full rounded-box border border-base-300 bg-base-200">
      <.table
        id="platform-labels-table"
        rows={@rows}
      >
        <:col :let={row} label="Tag">
          <.tag_badge tag={row} />
        </:col>
        <:col :let={row} label="Label">
          {row.label}
        </:col>
        <:col :let={row} label="Background">
          <.color_square_tag color={row.background} />
        </:col>
        <:col :let={row} label="Foreground">
          <.color_square_tag color={row.foreground} />
        </:col>
        <:col :let={row} label="Games">
          {row.count}
        </:col>
        <:action :let={row}>
          <.button icon="btn-square" patch={tag_route(row, @type, :edit)}>
            <.icon name="lucide-pencil" />
          </.button>
          <.button icon="btn-square" variant="btn-error" patch={tag_route(row, @type, :delete)}>
            <.icon name="lucide-trash" />
          </.button>
        </:action>
      </.table>
    </div>
    """
  end

  defp tag_route(tag, :platforms, :delete), do: ~p"/tags/platforms/#{tag.id}/delete"
  defp tag_route(tag, :platforms, :edit), do: ~p"/tags/platforms/#{tag.id}/edit"
  defp tag_route(tag, :statuses, :delete), do: ~p"/tags/statuses/#{tag.id}/delete"
  defp tag_route(tag, :statuses, :edit), do: ~p"/tags/statuses/#{tag.id}/edit"

  defp color_square_tag(assigns) do
    ~H"""
    <div class="flex gap-2 items-center">
      <.badge size="badge-sm" style={"background-color: #{@color}; border-color: #{@color}"} />
      <span>{@color}</span>
    </div>
    """
  end
end
