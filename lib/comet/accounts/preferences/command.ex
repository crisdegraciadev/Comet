defmodule Comet.Accounts.Preferences.Command do
  alias Comet.Repo
  alias Comet.Accounts.Preferences
  alias Comet.Accounts.User

  def change(%Preferences{} = preferences, %User{} = user, attrs \\ %{}) do
    Preferences.changeset(preferences, attrs, %{user: user})
  end

  def update(%Preferences{} = preferences, %User{} = user, attrs) do
    preferences |> change(user, attrs) |> Repo.update()
  end

  def create(%User{} = user, attrs) do
    %Preferences{cols: 8, assets: :cover, show_name: true} |> change(user, attrs) |> Repo.insert()
  end
end
