defmodule Comet.Tags do
  import Ecto.Query

  alias Comet.Accounts
  alias Comet.Repo

  def create(module, %Accounts.User{} = user, attrs) do
    struct(module)
    |> change(module, user, attrs)
    |> Repo.insert()
  end

  def update(%module{} = tag, %Accounts.User{} = user, attrs) do
    tag
    |> change(module, user, attrs)
    |> Repo.update()
  end

  def delete(%module{} = tag, %Accounts.User{} = user) do
    tag
    |> change(module, user)
    |> Repo.delete()
  end

  def change(%module{} = tag, module, %Accounts.User{} = user, attrs \\ %{}) do
    module.changeset(tag, attrs, %{user: user})
  end

  def all(module, %Accounts.User{id: user_id}) do
    module |> for_user(user_id) |> Repo.all()
  end

  def get!(module, %Accounts.User{id: user_id}, id) when is_binary(id),
    do: get!(module, %Accounts.User{id: user_id}, String.to_integer(id))

  def get!(module, %Accounts.User{id: user_id}, id) when is_integer(id) do
    module
    |> for_user(user_id)
    |> Repo.get!(id)
  end

  defp for_user(query, user_id) do
    where(query, [t], t.user_id == ^user_id)
  end
end
