defmodule Comet.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Comet.Posts` context.
  """

  @doc """
  Generate a comment.
  """
  def comment_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body"
      })

    {:ok, comment} = Comet.Posts.create_comment(scope, attrs)
    comment
  end
end
