defmodule CometWeb.Layouts do
  use CometWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil
  attr :current_module, :list, default: ["/", ""]

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.sidebar current_scope={@current_scope} current_module={@current_module}>
      <main class="px-4 py-8 lg:px-10 flex justify-center">
        <div class="space-y-6 w-full ">
          {render_slot(@inner_block)}
        </div>
      </main>
    </.sidebar>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil
  attr :current_module, :list, default: ["/", ""]

  slot :inner_block, required: true

  def settings(assigns) do
    ~H"""
    <.sidebar current_scope={@current_scope} current_module={@current_module}>
      <main class="px-4 py-20 lg:px-8">
        <div class="mx-auto space-y-4 max-w-2xl">
          {render_slot(@inner_block)}
        </div>
      </main>
    </.sidebar>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def login(assigns) do
    ~H"""
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="lucide-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="lucide-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  attr :current_scope, :map, default: nil
  attr :current_module, :string, default: "/"

  slot :inner_block, required: true

  def sidebar(assigns) do
    top_menu = [
      {"Backlog", ~p"/backlog/collection", "lucide-gamepad-2"},
      {"Browser", ~p"/browser/collection", "lucide-file-search"}
    ]

    bottom_menu = [
      {"Settings", ~p"/settings/account", "lucide-bolt"},
      {"Logout", ~p"/users/log-out", "lucide-log-out"}
    ]

    assigns = assigns |> assign(:top_menu, top_menu) |> assign(:bottom_menu, bottom_menu)

    ~H"""
    <div class="sidebar drawer lg:drawer-open">
      <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content bg-cm-black-100 flex flex-col">
        <label for="my-drawer-2" class="btn btn-primary drawer-button lg:hidden">
          Open drawer
        </label>
        <.topbar current_module={@current_module} />
        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side !overflow-visible">
        <label for="my-drawer-2" aria-label="close sidebar" class="drawer-overlay"></label>

        <div class="sidebar-menu menu bg-cm-black-200 border-r border-r-cm-grey text-base-content min-h-full w-70 p-2">
          <div class="navigation">
            <div class="user-settings bg-cm-grey p-2 rounded">
              <div class="flex gap-2">
                <.avatar size="small" />
                <div class="info">
                  <span class="font-medium">Joseph</span>
                  <span class="text-xs font-light text-base-content/50">
                    {@current_scope.user.email}
                  </span>
                </div>
              </div>
            </div>

            <ul class="p-2 !mt-0 text-cm-white text-cm-s min-h-full w-full">
              <.menu orientation="menu-vertical" class="p-0 w-full">
                <:item
                  :for={{label, path, icon} <- @top_menu}
                  href={path}
                  label={label}
                  icon={icon}
                  active={"/#{Enum.join(@current_module, "/")}" == path}
                />
              </.menu>
            </ul>
          </div>

          <ul class="p-2 !mt-0 text-cm-white text-cm-s min-h-full w-full">
            <.menu orientation="menu-vertical" class="p-0 w-full">
              <:item
                :for={{label, path, icon} <- @bottom_menu}
                href={path}
                label={label}
                icon={icon}
                active={"/#{Enum.join(@current_module, "/")}" == path}
              />
            </.menu>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  attr :current_module, :string, default: "/"

  defp topbar(assigns) do
    [main_path | _] = assigns.current_module
    {title, tabs} = topbar_module(main_path)

    assigns = assign(assigns, %{title: title, tabs: tabs})

    ~H"""
    <nav class="topbar navbar justify-between bg-cm-black-200 border-b border-b-cm-grey">
      <div class="navbar-start flex items-center">
        <span class="px-4 font-semibold text-xl">{@title}</span>
        <.menu :if={@tabs} class="p-0">
          <:item
            :for={{label, path} <- @tabs}
            href={path}
            label={label}
            active={"/#{Enum.join(@current_module, "/")}" == path}
          />
        </.menu>
      </div>
    </nav>
    """
  end

  defp topbar_module("settings") do
    {"Settings",
     [
       {"Account", ~p"/settings/account"},
       {"Profile", ~p"/settings/profile"},
       {"API", ~p"/settings/api_key"}
     ]}
  end

  defp topbar_module("backlog") do
    {"Backlog", []}
  end

  defp topbar_module("browser") do
    {"Browser", []}
  end
end
