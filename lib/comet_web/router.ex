defmodule CometWeb.Router do
  use CometWeb, :router

  import CometWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CometWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CometWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  if Application.compile_env(:comet, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CometWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", CometWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CometWeb.UserAuth, :require_authenticated}] do
      live "/users/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    scope "/settings" do
      live "/account", SettingsLive.Account
      live "/profile", SettingsLive.Profile
      live "/api_key", SettingsLive.ApiKey
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", CometWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CometWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
