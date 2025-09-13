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

  def platforms(:values), do: Map.values(@platforms)
  def platforms(), do: @platforms

  def statuses(:values), do: Map.values(@statuses)
  def statuses(), do: @statuses
end
