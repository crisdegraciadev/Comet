defmodule Comet.Tags.Platform.Query do
  import Ecto.Query

  alias Comet.Accounts.User
  alias Comet.Repo
  alias Comet.Tags.Platform

  def all(%User{id: user_id}) do
    Platform |> for_user(user_id) |> Repo.all()
  end

  defp for_user(query, user_id) do
    where(query, [g], g.user_id == ^user_id)
  end
end
