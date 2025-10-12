defmodule CometWeb.RootLive.Root do
  use CometWeb, :live_view

  def mount(params, session, socket) do
    {:ok, socket |> redirect(to: ~p"/backlog/collection")}
  end
end
