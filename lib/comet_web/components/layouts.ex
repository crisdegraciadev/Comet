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
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
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
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  defp theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <span
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </span>

      <span
        class="flex p-2 cursor-pointer w-1/3"
        variant="ghost"
        shape="circle"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </span>

      <span
        class="flex p-2 cursor-pointer w-1/3"
        variant="ghost"
        shape="circle"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </span>
    </div>
    """
  end

  attr :current_scope, :map, default: nil
  attr :current_module, :string, default: "/"

  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="sidebar drawer lg:drawer-open">
      <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col">
        <label for="my-drawer-2" class="btn btn-primary drawer-button lg:hidden">
          Open drawer
        </label>
        <.topbar current_module={@current_module} />
        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side !overflow-visible">
        <label for="my-drawer-2" aria-label="close sidebar" class="drawer-overlay"></label>

        <div class="sidebar-menu menu bg-base-200 text-base-content min-h-full w-70 p-2">
          <div class="navigation">
            <a href="/" class="flex-1 flex w-fit items-center gap-2 p-2">
              <img src={~p"/images/logo.svg"} width="44" />
              <span class="text-2xl font-semibold">Comet</span>
            </a>

            <ul class="menu bg-base-200 text-base-content min-h-full w-full">
              <li><.link href={~p"/dashboard/hub"}><.icon name="hero-home" />Dashboard</.link></li>
              <li><.link href={~p"/"}><.icon name="hero-magnifying-glass" />Browser</.link></li>
              <li>
                <.link href={~p"/backlog/collection"}>
                  <.icon name="hero-rectangle-stack" />Backlog
                </.link>
              </li>
            </ul>
          </div>

          <.dropdown
            :if={@current_scope}
            class="w-full"
            position="dropdown-right dropdown-end"
          >
            <:trigger>
              <div class="user-settings hover:bg-base-100 p-2 rounded">
                <div class="flex gap-2">
                  <.avatar size="small" />
                  <div class="info">
                    <span class="font-medium">Joseph</span>
                    <span class="text-xs font-light text-base-content/50">
                      {@current_scope.user.email}
                    </span>
                  </div>
                </div>
                <.icon name="hero-cog-6-tooth" />
              </div>
            </:trigger>

            <:actions>
              <.link href={~p"/settings/account"}>Settings</.link>
              <.link href={~p"/users/log-out"} method="delete">Log out</.link>
            </:actions>
          </.dropdown>
        </div>
      </div>
    </div>
    """
  end

  attr :current_module, :string, default: "/"

  defp topbar(assigns) do
    [main_path, sub_path] = assigns.current_module

    {title, tabs} = topbar_module(main_path)

    assigns =
      assigns
      |> assign(%{
        title: title,
        tabs: tabs,
        sub_path: sub_path
      })

    ~H"""
    <nav class="topbar navbar justify-between">
      <div class="navbar-start flex items-center">
        <span class="px-4 font-semibold text-xl">{@title}</span>
        <div class="navigation">
          <a
            :for={{label, path} <- @tabs}
            class={["nav-item", String.contains?(path, @sub_path) && "nav-item-active"]}
            href={path}
          >
            {label}
          </a>
        </div>
      </div>
      <div class="navbar-end">
        <.theme_toggle />
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
    {"Backlog",
     [
       {"Collection", ~p"/backlog/collection"}
     ]}
  end


  defp topbar_module("dashboard") do
    {"Dashboard",
     [
       {"Hub", ~p"/dashboard/hub"}
     ]}
  end
end
