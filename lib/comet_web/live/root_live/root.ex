defmodule CometWeb.RootLive.Root do
  use CometWeb, :live_view

  def mount(_params, _session, socket), do: {:ok, socket |> redirect(to: ~p"/backlog/collection")}
end
