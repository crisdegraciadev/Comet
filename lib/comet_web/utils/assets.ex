defmodule CometWeb.Utils.Assets do
  def main_asset_url([]), do: nil

  def main_asset_url(assets) do
    assets
    |> Enum.find(Enum.at(assets, 0), fn asset -> asset.style == "official" end)
    |> Map.get(:url)
  end
end
