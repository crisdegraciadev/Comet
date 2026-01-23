defmodule Comet.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Comet.Repo

  alias Comet.Tags.Platform
  alias Comet.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any platform changes.

  The broadcasted messages match the pattern:

    * {:created, %Platform{}}
    * {:updated, %Platform{}}
    * {:deleted, %Platform{}}

  """
  def subscribe_platforms(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Comet.PubSub, "user:#{key}:platforms")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Comet.PubSub, "user:#{key}:platforms", message)
  end

  @doc """
  Returns the list of platforms.

  ## Examples

      iex> list_platforms(scope)
      [%Platform{}, ...]

  """
  def list_platforms(%Scope{} = scope) do
    Repo.all_by(Platform, user_id: scope.user.id)
  end

  @doc """
  Gets a single platform.

  Raises `Ecto.NoResultsError` if the Platform does not exist.

  ## Examples

      iex> get_platform!(scope, 123)
      %Platform{}

      iex> get_platform!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_platform!(%Scope{} = scope, id) do
    Repo.get_by!(Platform, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a platform.

  ## Examples

      iex> create_platform(scope, %{field: value})
      {:ok, %Platform{}}

      iex> create_platform(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_platform(%Scope{} = scope, attrs) do
    with {:ok, platform = %Platform{}} <-
           %Platform{}
           |> Platform.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, platform})
      {:ok, platform}
    end
  end

  @doc """
  Updates a platform.

  ## Examples

      iex> update_platform(scope, platform, %{field: new_value})
      {:ok, %Platform{}}

      iex> update_platform(scope, platform, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_platform(%Scope{} = scope, %Platform{} = platform, attrs) do
    true = platform.user_id == scope.user.id

    with {:ok, platform = %Platform{}} <-
           platform
           |> Platform.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, platform})
      {:ok, platform}
    end
  end

  @doc """
  Deletes a platform.

  ## Examples

      iex> delete_platform(scope, platform)
      {:ok, %Platform{}}

      iex> delete_platform(scope, platform)
      {:error, %Ecto.Changeset{}}

  """
  def delete_platform(%Scope{} = scope, %Platform{} = platform) do
    true = platform.user_id == scope.user.id

    with {:ok, platform = %Platform{}} <-
           Repo.delete(platform) do
      broadcast(scope, {:deleted, platform})
      {:ok, platform}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking platform changes.

  ## Examples

      iex> change_platform(scope, platform)
      %Ecto.Changeset{data: %Platform{}}

  """
  def change_platform(%Scope{} = scope, %Platform{} = platform, attrs \\ %{}) do
    true = platform.user_id == scope.user.id

    Platform.changeset(platform, attrs, scope)
  end

  alias Comet.Tags.Status
  alias Comet.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any status changes.

  The broadcasted messages match the pattern:

    * {:created, %Status{}}
    * {:updated, %Status{}}
    * {:deleted, %Status{}}

  """
  def subscribe_statuses(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Comet.PubSub, "user:#{key}:statuses")
  end

  @doc """
  Returns the list of statuses.

  ## Examples

      iex> list_statuses(scope)
      [%Status{}, ...]

  """
  def list_statuses(%Scope{} = scope) do
    Repo.all_by(Status, user_id: scope.user.id)
  end

  @doc """
  Gets a single status.

  Raises `Ecto.NoResultsError` if the Status does not exist.

  ## Examples

      iex> get_status!(scope, 123)
      %Status{}

      iex> get_status!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_status!(%Scope{} = scope, id) do
    Repo.get_by!(Status, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a status.

  ## Examples

      iex> create_status(scope, %{field: value})
      {:ok, %Status{}}

      iex> create_status(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_status(%Scope{} = scope, attrs) do
    with {:ok, status = %Status{}} <-
           %Status{}
           |> Status.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, status})
      {:ok, status}
    end
  end

  @doc """
  Updates a status.

  ## Examples

      iex> update_status(scope, status, %{field: new_value})
      {:ok, %Status{}}

      iex> update_status(scope, status, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_status(%Scope{} = scope, %Status{} = status, attrs) do
    true = status.user_id == scope.user.id

    with {:ok, status = %Status{}} <-
           status
           |> Status.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, status})
      {:ok, status}
    end
  end

  @doc """
  Deletes a status.

  ## Examples

      iex> delete_status(scope, status)
      {:ok, %Status{}}

      iex> delete_status(scope, status)
      {:error, %Ecto.Changeset{}}

  """
  def delete_status(%Scope{} = scope, %Status{} = status) do
    true = status.user_id == scope.user.id

    with {:ok, status = %Status{}} <-
           Repo.delete(status) do
      broadcast(scope, {:deleted, status})
      {:ok, status}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking status changes.

  ## Examples

      iex> change_status(scope, status)
      %Ecto.Changeset{data: %Status{}}

  """
  def change_status(%Scope{} = scope, %Status{} = status, attrs \\ %{}) do
    true = status.user_id == scope.user.id

    Status.changeset(status, attrs, scope)
  end
end
