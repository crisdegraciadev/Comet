defmodule Comet.Services.Constants do
  @platforms %{
    pc: {"PC", :pc},
    ps1: {"PS1", :ps1},
    ps2: {"PS2", :ps2},
    ps3: {"PS3", :ps3},
    ps4: {"PS4", :ps4},
    ps5: {"PS5", :ps5},
    psp: {"PSP", :psp},
    switch: {"Switch", :switch}
  }

  @statuses %{
    completed: {"Completed", :completed},
    in_progress: {"In Progress", :in_progress},
    pending: {"Pending", :pending}
  }

  @groups %{
    platform: {"Platform", :platform},
    status: {"Status", :status}
  }

  @sorts %{
    name: {"Name", :name},
    platform: {"Platform", :platform},
    status: {"Status", :status}
  }

  @orders %{
    asc: {"Asc", :asc},
    desc: {"Desc", :desc}
  }

  def platforms(:values), do: Map.values(@platforms)
  def platforms, do: @platforms

  def statuses(:values), do: Map.values(@statuses)
  def statuses, do: @statuses

  def groups(:values), do: Map.values(@groups)
  def groups, do: @groups

  def sorts(:values), do: Map.values(@sorts)
  def sorts, do: @sorts

  def orders(:values), do: Map.values(@orders)
  def orders, do: @orders
end
