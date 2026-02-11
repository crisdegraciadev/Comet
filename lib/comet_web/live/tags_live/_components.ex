defmodule CometWeb.Live.TagsLive.Components do
  use Phoenix.Component
  use CometWeb, :html

  alias Comet.Accounts

  attr :games, :list, required: true
  attr :preferences, Accounts.Preference, required: true

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
  attr :preferences, Accounts.Preference, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :type, :atom, values: ~w(platforms statuses)a

  def create_tag_modal(assigns) do
    assigns = assign_form_and_preview(assigns)

    ~H"""
    <.modal id="create-tag-modal" backdrop_link={tag_route(nil, @type, :list)}>
      <:header title="Create tag" />
      <:body>
        <.tag_form
          id="create-tag-form"
          form={@form}
          preview_tag={@preview_tag}
          event={:create}
        />
      </:body>
      <:footer>
        <.button variant="btn-primary" type="submit" form="create-tag-form">
          Create
        </.button>
        <.button variant="btn-error" patch={tag_route(nil, @type, :list)}>
          Cancel
        </.button>
      </:footer>
    </.modal>
    """
  end

  attr :user, Accounts.User, required: true
  attr :preferences, Accounts.Preference, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :type, :atom, values: ~w(platforms statuses)a

  def edit_tag_modal(assigns) do
    assigns = assign_form_and_preview(assigns)

    ~H"""
    <.modal id="edit-tag-modal" backdrop_link={tag_route(nil, @type, :list)}>
      <:header title="Update tag" />
      <:body>
        <.tag_form
          id="edit-tag-form"
          form={@form}
          preview_tag={@preview_tag}
          event={:update}
        />
      </:body>
      <:footer>
        <.button variant="btn-primary" type="submit" form="edit-tag-form">
          Save
        </.button>
        <.button variant="btn-error" patch={tag_route(nil, @type, :list)}>
          Cancel
        </.button>
      </:footer>
    </.modal>
    """
  end

  attr :id, :string, required: true
  attr :form, :any, required: true
  attr :preview_tag, :map, required: true
  attr :event, :atom, required: true, values: ~w(create update)a

  def tag_form(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <div class="flex justify-center gap-2">
        <.tag_badge id="tag-preview" tag={@preview_tag} />
      </div>

      <.form
        id={@id}
        class="flex flex-col gap-2 h-full justify-between"
        for={@form}
        phx-submit={@event}
        phx-change="reload_preview"
      >
        <.input field={@form[:label]} label="Label" required autocomplete="off" />

        <.input
          type="color"
          field={@form[:background]}
          label="Background"
          required
          autocomplete="off"
          data={
            %{
              targets: [
                %{
                  type: :preview,
                  id: "tag-preview",
                  styleProps: ["background-color", "border-color"]
                }
              ]
            }
          }
        />

        <.input
          type="color"
          field={@form[:foreground]}
          label="Foreground"
          required
          autocomplete="off"
          data={
            %{
              targets: [
                %{
                  type: :preview,
                  id: "tag-preview",
                  styleProps: ["color"]
                }
              ]
            }
          }
        />
      </.form>
    </div>
    """
  end

  attr :tag, :any, required: true
  attr :changeset, Ecto.Changeset, required: true
  attr :type, :atom, values: ~w(platforms statuses)a

  def delete_tag_modal(assigns) do
    ~H"""
    <.modal id="create-tag-modal" backdrop_link={tag_route(nil, @type, :list)}>
      <:header title="Delete tag" />
      <:body>
        <div class="flex flex-col gap-4">
          <div class="flex justify-center gap-2">
            <.tag_badge tag={@tag} />
          </div>

          <p class="text-center">
            You are about to <span class="font-bold">delete</span>
            the following tag from your account. To perform this action the tag should not be attached to any game.
            <span class="font-bold">This action can't be undone.</span>
          </p>

          <ul :if={@changeset.errors != []} class="text-error">
            <li :for={err <- pretty_errors(@changeset)} class="text-center">
              <.icon name="lucide-info" /> {err}
            </li>
          </ul>
        </div>
      </:body>
      <:footer>
        <.button phx-click="delete" phx-value-id={@tag.id}>Confirm</.button>
        <.button variant="btn-error" patch={tag_route(nil, :platforms, :list)}>Cancel</.button>
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

  defp color_square_tag(assigns) do
    ~H"""
    <div class="flex gap-2 items-center">
      <.badge size="badge-sm" style={"background-color: #{@color}; border-color: #{@color}"} />
      <span>{@color}</span>
    </div>
    """
  end

  defp tag_route(nil, :platforms, :list), do: ~p"/tags/platforms"
  defp tag_route(tag, :platforms, :delete), do: ~p"/tags/platforms/#{tag.id}/delete"
  defp tag_route(tag, :platforms, :edit), do: ~p"/tags/platforms/#{tag.id}/edit"
  defp tag_route(nil, :statuses, :list), do: ~p"/tags/statuses"
  defp tag_route(tag, :statuses, :delete), do: ~p"/tags/statuses/#{tag.id}/delete"
  defp tag_route(tag, :statuses, :edit), do: ~p"/tags/statuses/#{tag.id}/edit"

  defp assign_form_and_preview(%{changeset: changeset} = assigns) do
    form = to_form(changeset)

    values =
      case map_size(changeset.changes) do
        0 -> changeset.data
        _ -> changeset.changes
      end

    preview_tag = %{
      label: Map.get(values, :label, ""),
      background: Map.get(values, :background, ""),
      foreground: Map.get(values, :foreground, "")
    }

    assigns
    |> assign(:form, form)
    |> assign(:preview_tag, preview_tag)
  end

  def pretty_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.flat_map(fn {_field, msgs} -> msgs end)
  end
end
