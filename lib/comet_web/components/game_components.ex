defmodule CometWeb.GameComponents do
  use Phoenix.Component
  use Gettext, backend: CometWeb.Gettext

  import CometWeb.CoreComponents

  alias Comet.Accounts
  alias Comet.Games

  attr :id, :string, required: true
  attr :game, :map, required: true
  attr :backdrop_link, :string
  attr :rest, :global

  slot :actions
  slot :inner_block

  def game_modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal modal-open shadow-lg" {@rest}>
      <div class="game-modal modal-box bg-cm-black-200 border border-cm-black-300 !shadow-none max-w-[calc(1920px*0.4)] flex flex-col gap-5">
        <div class="relative h-[calc((900px*0.3)+(0.25rem*8))]">
          <.hero url={@game.hero} />
          <.cover url={@game.cover} />
        </div>

        <div class="flex flex-col gap-4 mx-6">
          <div class="flex gap-2 justify-between">
            <h1 class="font-semibold text-4xl">
              {@game.name}
            </h1>

            <div :if={@actions != []} class="flex gap-2">
              {render_slot(@actions)}
            </div>
          </div>

          {render_slot(@inner_block)}
        </div>
      </div>

      <.link :if={assigns[:backdrop_link]} class="modal-backdrop" patch={@backdrop_link}></.link>
    </dialog>
    """
  end

  defp hero(assigns) do
    ~H"""
    <%= if @url do %>
      <img
        src={@url}
        class="h-[calc(620px*0.4)] rounded-md bg-white/30 brightness-50 border border-cm-black-300"
      />
    <% else %>
      <div class="w-full h-[calc(620px*0.4)] flex justify-center items-center rounded-md bg-cm-black-100 border border-cm-black-300">
        <.icon name="lucide-file-image" size="size-16" />
      </div>
    <% end %>
    """
  end

  defp cover(assigns) do
    ~H"""
    <%= if @url do %>
      <img
        src={@url}
        class="h-[calc(900px*0.3)] rounded-md absolute top-8 left-6"
      />
    <% else %>
      <div class="h-[calc(900px*0.3)] w-[calc(600px*0.3)] bg-cm-black-100 flex justify-center items-center rounded-md absolute top-8 left-6 border border-cm-black-300">
        <.icon name="lucide-file-image" size="size-16" />
      </div>
    <% end %>
    """
  end

  attr :id, :string, required: true
  attr :game, Games.Game, required: true
  attr :preferences, Accounts.Preference, required: true
  attr :path_link, :string
  attr :class, :string, default: nil

  def game_card(%{preferences: %{assets: :cover}} = assigns) do
    ~H"""
    <.link id={@id} patch={@path_link}>
      <div class={[
        "rounded-md flex flex-col gap-2 game-cover-shadow border border-cm-black-300 bg-cm-black-200 relative",
        @class
      ]}>
        <div class="absolute top-2 left-2 flex gap-1 flex-col z-1">
          <.tag_badge tag={@game.status} />
          <.tag_badge tag={@game.platform} />
        </div>
        <img
          class={[
            "aspect-2/3",
            if(!@preferences.show_name, do: "rounded-md", else: "rounded-tl-md rounded-tr-md")
          ]}
          src={@game.cover}
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

  def game_card(%{preferences: %{assets: :hero}} = assigns) do
    ~H"""
    <.link id={@id} patch={@path_link}>
      <div class="rounded-md flex flex-col gap-2 game-cover-shadow border border-cm-black-300 bg-cm-black-200 relative">
        <div class="absolute top-2 left-2 flex gap-1 flex-col z-1">
          <.tag_badge tag={@game.status} />
          <.tag_badge tag={@game.platform} />
        </div>

        <div
          :if={@game.hero == nil}
          class="w-full h-full flex flex-col items-center justify-center bg-cm-black-100"
        >
        </div>

        <img
          class={[
            "aspect-96/31",
            if(!@preferences.show_name, do: "rounded-md", else: "rounded-tl-md rounded-tr-md")
          ]}
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

  attr :tag, :any, required: true
  attr :rest, :global

  def tag_badge(%{tag: %{label: label, background: background, foreground: foreground}} = assigns) do
    assigns =
      assigns
      |> assign(:label, label)
      |> assign(
        :style,
        "background-color: #{background}; border-color: #{background}; color: #{foreground}"
      )

    ~H"""
    <.badge style={@style} {@rest}>
      {@label}
    </.badge>
    """
  end
end
