defmodule Comet.PostsTest do
  use Comet.DataCase

  alias Comet.Posts

  describe "comments" do
    alias Comet.Posts.Comment

    import Comet.AccountsFixtures, only: [user_scope_fixture: 0]
    import Comet.PostsFixtures

    @invalid_attrs %{body: nil}

    test "list_comments/1 returns all scoped comments" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      comment = comment_fixture(scope)
      other_comment = comment_fixture(other_scope)
      assert Posts.list_comments(scope) == [comment]
      assert Posts.list_comments(other_scope) == [other_comment]
    end

    test "get_comment!/2 returns the comment with given id" do
      scope = user_scope_fixture()
      comment = comment_fixture(scope)
      other_scope = user_scope_fixture()
      assert Posts.get_comment!(scope, comment.id) == comment
      assert_raise Ecto.NoResultsError, fn -> Posts.get_comment!(other_scope, comment.id) end
    end

    test "create_comment/2 with valid data creates a comment" do
      valid_attrs = %{body: "some body"}
      scope = user_scope_fixture()

      assert {:ok, %Comment{} = comment} = Posts.create_comment(scope, valid_attrs)
      assert comment.body == "some body"
      assert comment.user_id == scope.user.id
    end

    test "create_comment/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.create_comment(scope, @invalid_attrs)
    end

    test "update_comment/3 with valid data updates the comment" do
      scope = user_scope_fixture()
      comment = comment_fixture(scope)
      update_attrs = %{body: "some updated body"}

      assert {:ok, %Comment{} = comment} = Posts.update_comment(scope, comment, update_attrs)
      assert comment.body == "some updated body"
    end

    test "update_comment/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      comment = comment_fixture(scope)

      assert_raise MatchError, fn ->
        Posts.update_comment(other_scope, comment, %{})
      end
    end

    test "update_comment/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      comment = comment_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Posts.update_comment(scope, comment, @invalid_attrs)
      assert comment == Posts.get_comment!(scope, comment.id)
    end

    test "delete_comment/2 deletes the comment" do
      scope = user_scope_fixture()
      comment = comment_fixture(scope)
      assert {:ok, %Comment{}} = Posts.delete_comment(scope, comment)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_comment!(scope, comment.id) end
    end

    test "delete_comment/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      comment = comment_fixture(scope)
      assert_raise MatchError, fn -> Posts.delete_comment(other_scope, comment) end
    end

    test "change_comment/2 returns a comment changeset" do
      scope = user_scope_fixture()
      comment = comment_fixture(scope)
      assert %Ecto.Changeset{} = Posts.change_comment(scope, comment)
    end
  end
end
