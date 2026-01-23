defmodule Comet.Tags do
  import Ecto.Query

  alias Comet.Accounts.User
  alias Comet.Repo
  alias Comet.Tags.Platform
  alias Comet.Tags.Status

  def all_statuses(%User{id: user_id}), do: Status |> for_user(user_id) |> Repo.all()

  def all_platforms(%User{id: user_id}), do: Platform |> for_user(user_id) |> Repo.all()

  defp for_user(query, user_id) do
    where(query, [t], t.user_id == ^user_id)
  end
end
