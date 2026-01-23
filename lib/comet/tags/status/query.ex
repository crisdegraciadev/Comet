defmodule Comet.Tags.Status.Query do
  import Ecto.Query

  alias Comet.Accounts.User
  alias Comet.Repo
  alias Comet.Tags.Status

  def all(%User{id: user_id}) do
    Status |> for_user(user_id) |> Repo.all()
  end

  defp for_user(query, user_id) do
    where(query, [g], g.user_id == ^user_id)
  end
end
