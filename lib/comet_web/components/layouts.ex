defmodule CometWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use CometWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.sidebar current_scope={@current_scope}>
      <main class="px-4 py-20 sm:px-6 lg:px-8">
        <div class="mx-auto max-w-2xl space-y-4">
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

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
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

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  attr :current_scope, :map, default: nil

  slot :inner_block, required: true

  def sidebar(assigns) do
    ~H"""
    <div class="sidebar drawer lg:drawer-open">
      <input id="my-drawer-2" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col">
        <label for="my-drawer-2" class="btn btn-primary drawer-button lg:hidden">
          Open drawer
        </label>

        <nav class="navbar justify-between border-b border-base-300">
          <div class="navbar-start flex">
            <ul class="menu menu-horizontal px-1">
              <li><a>Settings</a></li>
            </ul>
          </div>
          <div class="navbar-end">
            <.theme_toggle />
          </div>
        </nav>

        {render_slot(@inner_block)}
      </div>
      <div class="drawer-side !overflow-visible">
        <label for="my-drawer-2" aria-label="close sidebar" class="drawer-overlay"></label>

        <div class="menu bg-base-200 text-base-content min-h-full w-70 p-2">
          <div class="navigation">
            <a href="/" class="flex-1 flex w-fit items-center gap-2 p-2">
              <img src={~p"/images/logo.svg"} width="44" />
              <span class="text-2xl font-semibold">Comet</span>
            </a>

            <ul class="menu bg-base-200 text-base-content min-h-full w-full">
              <li><.link href={~p"/"}><.icon name="hero-home" />Home</.link></li>
              <li><.link href={~p"/"}><.icon name="hero-magnifying-glass" />Browser</.link></li>
              <li><.link href={~p"/"}><.icon name="hero-rectangle-stack" />Backlog</.link></li>
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
              <.link href={~p"/users/settings"}>Settings</.link>
              <.link href={~p"/users/log-out"} method="delete">Log out</.link>
            </:actions>
          </.dropdown>
        </div>
      </div>
    </div>
    """
  end
end
