defmodule Comet.Accounts do
  import Ecto.Query, warn: false

  alias Comet.Repo
  alias Comet.Accounts.{User, UserToken, Profile, Preferences}

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def build_profile(user) do
    %Profile{}
    |> Profile.changeset(%{}, %{user: user})
  end

  def build_preferences(user) do
    %Preferences{}
    |> Preferences.changeset(%{cols: 10, assets: :cover, name: true}, %{user: user})
  end

  def register_user(attrs) do
    Repo.transaction(fn ->
      changeset =
        %User{}
        |> User.email_changeset(attrs)
        |> User.password_changeset(attrs)

      with {:ok, user} <- Repo.insert(changeset) do
        build_profile(user) |> Repo.insert()
        build_preferences(user) |> Repo.insert()

        {:ok, user}
      else
        error -> Repo.rollback(error)
      end
    end)
    |> case do
      {:ok, {:ok, user}} -> {:ok, user}
      {:error, error} -> error
    end
  end

  def sudo_mode?(user, minutes \\ -20000)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)
        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))
        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  def change_user_registration(user, attrs \\ %{}) do
    user
    |> User.email_changeset(attrs)
    |> User.password_changeset(attrs)
  end

  def change_profile(profile, attrs \\ %{}) do
    Comet.Accounts.Profile.changeset(profile, attrs, %{user: profile.user}, require_fields: true)
  end

  def update_profile(profile, attrs) do
    profile
    |> Comet.Accounts.Profile.changeset(attrs, %{user: profile.user}, require_fields: true)
    |> Repo.update()
  end

  def update_user_email_without_confirmation(%User{} = user, new_email)
      when is_binary(new_email) do
    user
    |> User.email_changeset(%{"email" => new_email})
    |> Repo.update()
  end

  def get_user_with_profile!(user_id) do
    Repo.get!(User, user_id)
    |> Repo.preload(profile: :user)
  end
end
