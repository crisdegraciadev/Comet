defmodule Comet.Cache do
  @moduledoc """
  Simple ETS-based cache service.
  Source: https://www.openmymind.net/Building-A-Cache-In-Elixir
  """

  use GenServer

  @table :global_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{}}
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value, expiry}] ->
        if :erlang.system_time(:second) < expiry do
          value
        else
          :ets.delete(@table, key)
          nil
        end

      [] ->
        nil
    end
  end

  def put(key, value, ttl \\ 24 * 60 * 60) do
    expires = :erlang.system_time(:second) + ttl
    :ets.insert(@table, {key, value, expires})
  end
end
