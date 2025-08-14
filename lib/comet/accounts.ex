defmodule Comet.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Comet.Repo
  alias Comet.Accounts.{User, UserToken}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Builds a changeset for a new profile for the given user.
  This function is used when a user is created and their profile does not yet exist.
  """
  def build_profile_for_user(user) do
    %Comet.Accounts.Profile{}
    |> Comet.Accounts.Profile.changeset(%{}, %{user: user})
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    Repo.transaction(fn ->
      changeset =
        %User{}
        |> User.email_changeset(attrs)
        |> User.password_changeset(attrs)

      with {:ok, user} <- Repo.insert(changeset) do
        build_profile_for_user(user)
        |> Repo.insert()
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

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Comet.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Comet.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)
        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))
        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Changesets

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user registration.
  This function is used when a user is registering for the first time.
  It includes email and password changesets.
  """
  def change_user_registration(user, attrs \\ %{}) do
    user
    |> User.email_changeset(attrs)
    |> User.password_changeset(attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile.
  """
  def change_profile(profile, attrs \\ %{}) do
    Comet.Accounts.Profile.changeset(profile, attrs, %{user: profile.user}, require_fields: true)
  end

  @doc """
  Updates the user profile.
  """
  def update_profile(profile, attrs) do
    profile
    |> Comet.Accounts.Profile.changeset(attrs, %{user: profile.user}, require_fields: true)
    |> Repo.update()
  end

  @doc """
  Updates a user's email directly without requiring confirmation.

  ## Examples

      iex> update_user_email_without_confirmation(user, "new@example.com")
      {:ok, %User{}}

      iex> update_user_email_without_confirmation(user, "invalid")
      {:error, %Ecto.Changeset{}}
  """
  def update_user_email_without_confirmation(%User{} = user, new_email) when is_binary(new_email) do
    user
    |> User.email_changeset(%{"email" => new_email})
    |> Repo.update()
  end
end
