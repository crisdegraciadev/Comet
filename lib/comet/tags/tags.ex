defmodule Comet.Tags do
  import Ecto.Query

  alias Comet.Accounts
  alias Comet.Repo
  alias Comet.Tags

  def create_platform(%Accounts.User{} = user, attrs) do
    %Tags.Platform{} |> change_platform(user, attrs) |> Repo.insert()
  end

  def create_status(%Accounts.User{} = user, attrs) do
    %Tags.Status{} |> change_status(user, attrs) |> Repo.insert()
  end

  def change_platform(%Tags.Platform{} = platform, %Accounts.User{} = user, attrs \\ %{}) do
    Tags.Platform.changeset(platform, attrs, %{user: user})
  end

  def change_status(%Tags.Status{} = status, %Accounts.User{} = user, attrs \\ %{}) do
    Tags.Status.changeset(status, attrs, %{user: user})
  end

  def update_platform(%Tags.Platform{} = platform, %Accounts.User{} = user, attrs) do
    platform |> change_platform(user, attrs) |> Repo.update()
  end

  def update_status(%Tags.Status{} = status, %Accounts.User{} = user, attrs) do
    status |> change_status(user, attrs) |> Repo.update()
  end

  def delete_platform(%Tags.Platform{} = platform, %Accounts.User{} = user) do
    platform |> change_platform(user) |> Repo.delete()
  end

  def delete_status(%Tags.Status{} = status, %Accounts.User{} = user) do
    status |> change_status(user) |> Repo.delete()
  end

  def all_statuses(%Accounts.User{id: user_id}),
    do: Tags.Status |> for_user(user_id) |> Repo.all()

  def all_platforms(%Accounts.User{id: user_id}),
    do: Tags.Platform |> for_user(user_id) |> Repo.all()

  def get_platform!(%Accounts.User{id: user_id}, id) when is_integer(id) do
    Tags.Platform
    |> for_user(user_id)
    |> Repo.get!(id)
  end

  def get_platform!(%Accounts.User{} = user, id) when is_binary(id),
    do: get_platform!(user, String.to_integer(id))

  def get_status!(%Accounts.User{id: user_id}, id) when is_integer(id) do
    Tags.Status
    |> for_user(user_id)
    |> Repo.get!(id)
  end

  def get_status!(%Accounts.User{} = user, id) when is_binary(id),
    do: get_status!(user, String.to_integer(id))

  defp for_user(query, user_id) do
    where(query, [t], t.user_id == ^user_id)
  end
end
