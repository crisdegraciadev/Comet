defmodule CometWeb.TagsLive.Tags do
  use CometWeb, :live_view

  def mount(_params, _session, socket), do: {:ok, socket |> redirect(to: ~p"/tags/platforms")}
end
