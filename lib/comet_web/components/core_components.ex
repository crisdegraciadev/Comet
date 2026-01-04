defmodule CometWeb.CoreComponents do
  use Phoenix.Component
  use Gettext, backend: CometWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :backdrop_link, :string
  attr :rest, :global

  slot :inner_block

  def modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal modal-open shadow-lg bg-transparent" {@rest}>
      <div class="modal-box bg-cm-black-200 border border-cm-black-300 !shadow-none">
        {render_slot(@inner_block)}
      </div>

      <.link :if={assigns[:backdrop_link]} class="modal-backdrop" patch={@backdrop_link}></.link>
    </dialog>
    """
  end

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="lucide-info" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="lucide-circle-x" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <.icon name="lucide-x-mark" class="size-5 cursor-pointer opacity-40 group-hover:opacity-70" />
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :variant, :string,
    values:
      ~w(btn-primary btn-secondary btn-neutral btn-accent btn-info btn-success btn-warning btn-error btn-ghost btn-link),
    default: "btn-primary"

  attr :size, :string, values: ~w(btn-xs btn-sm btn-l btn-xl)
  attr :icon, :string, values: ~w(btn-square btn-circle)
  attr :soft, :boolean, default: false
  attr :outline, :boolean, default: false
  attr :dash, :boolean, default: false
  attr :active, :boolean, default: false
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    assigns =
      assigns
      |> assign(:class, [
        "btn shrink-1",
        assigns[:variant],
        assigns[:size],
        assigns[:icon],
        assigns[:soft] && "btn-soft",
        assigns[:outline] && "btn-outline",
        assigns[:dash] && "btn-dash",
        assigns[:active] && "btn-active",
        assigns[:class]
      ])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>{render_slot(@inner_block)}</button>
      """
    end
  end

  attr :class, :string, default: nil

  attr :color, :string,
    values: ~w(alert-info alert-success alert-warning alert-error),
    default: "alert-info"

  attr :soft, :boolean, default: false
  attr :outline, :boolean, default: false
  attr :dash, :boolean, default: false

  slot :inner_block, required: true

  def alert(assigns) do
    assigns =
      assigns
      |> assign(:class, [
        "alert",
        assigns[:color],
        assigns[:soft] && "alert-soft",
        assigns[:outline] && "alet-outline",
        assigns[:dash] && "alet-dash",
        assigns[:class]
      ])

    ~H"""
    <div role="alert" class={@class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :label, :string, default: nil
  attr :class, :string, default: nil

  def divider(assigns) do
    ~H"""
    <div class={["divider", @class]}>
      <span :if={@label} class="text-xs text-base-content/40">{@label}</span>
    </div>
    """
  end

  slot :subtitle
  slot :actions
  slot :inner_block, required: true

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  attr :name, :string, required: true
  attr :size, :string, default: "size-4"
  attr :class, :string, default: nil

  def icon(%{name: "lucide-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @size, @class]} />
    """
  end

  attr :size, :string, values: ~w(large medium small), default: "medium"
  attr :email, :string, default: "comet@email.com"

  def avatar(assigns) do
    {wrapper_size, text_size} =
      case assigns.size do
        "large" -> {"w-24", "text-3xl"}
        "medium" -> {"w-16", "text-xl"}
        "small" -> {"w-10", "text-base"}
        "xsmall" -> {"w-8", "text-xs"}
      end

    placeholder_char = assigns.email |> String.at(0) |> String.upcase()

    assigns =
      assigns
      |> assign(%{
        wrapper_size: wrapper_size,
        text_size: text_size,
        placeholder_char: placeholder_char
      })

    ~H"""
    <div class="avatar avatar-placeholder">
      <div class={["bg-neutral text-neutral-content  rounded", @wrapper_size]}>
        <span class={@text_size}>{@placeholder_char}</span>
      </div>
    </div>
    """
  end

  attr :position, :string, default: "dropdown-bottom"
  attr :class, :string, default: nil

  slot :trigger, required: true
  slot :actions, required: true

  def dropdown(assigns) do
    ~H"""
    <div class={["dropdown", @position, @class]}>
      <div class="cursor-pointer" tabindex="0" role="button">{render_slot(@trigger)}</div>
      <ul tabindex="0" class="dropdown-content menu bg-base-300 rounded-box w-52 p-2 shadow-sm">
        <li :for={action <- @actions}>
          {render_slot(action)}
        </li>
      </ul>
    </div>
    """
  end

  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"

  attr :color, :string,
    values: [
      nil,
      "badge-primary",
      "badge-secondary",
      "badge-accent",
      "badge-neutral",
      "badge-info",
      "badge-success",
      "badge-warning",
      "badge-error"
    ],
    default: nil

  attr :variant, :string, values: [nil, "soft", "outline", "dash", "ghost"], default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "badge",
      "badge-#{@size}",
      @color,
      @variant && "badge-#{@variant}",
      @class
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :width, :string, default: nil
  attr :height, :string, default: nil

  def skeleton(assigns) do
    ~H"""
    <div class={["skeleton bg-cm-black-100", @width, @height]} />
    """
  end

  attr :orientation, :string, default: "menu-horizontal"
  attr :class, :string, default: nil
  attr :title, :string, default: nil

  slot :item do
    attr :label, :string
    attr :href, :string
    attr :icon, :string
    attr :active, :boolean
  end

  def menu(assigns) do
    ~H"""
    <ul class={["menu gap-1", @orientation, @class]}>
      <li :if={@title} class="menu-title">{@title}</li>
      <li :for={item <- @item}>
        <.link class={[item.active && "menu-active"]} navigate={item.href}>
          <.icon :if={item[:icon]} name={item.icon} /> {item.label}
        </.link>
      </li>
    </ul>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(CometWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CometWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
