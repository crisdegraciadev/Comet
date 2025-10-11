defmodule Comet.Accounts.Preferences.Query do
  import Ecto.Query

  alias Comet.Repo
  alias Comet.Accounts.Preferences
  alias Comet.Accounts.User

  def get!(%User{id: user_id}) do
    Preferences
    |> for_user(user_id)
    |> Repo.one!()
  end

  defp for_user(query, user_id) do
    where(query, [g], g.user_id == ^user_id)
  end
end
