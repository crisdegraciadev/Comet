defmodule CometWeb.Utils.Input do
  def tag_to_select(tags) do
    Enum.map(tags, fn t -> {t.label, t.id} end)
  end
end
