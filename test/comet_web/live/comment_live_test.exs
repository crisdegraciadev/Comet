defmodule CometWeb.CommentLiveTest do
  use CometWeb.ConnCase

  import Phoenix.LiveViewTest
  import Comet.PostsFixtures

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}

  setup :register_and_log_in_user

  defp create_comment(%{scope: scope}) do
    comment = comment_fixture(scope)

    %{comment: comment}
  end

  describe "Index" do
    setup [:create_comment]

    test "lists all comments", %{conn: conn, comment: comment} do
      {:ok, _index_live, html} = live(conn, ~p"/comments")

      assert html =~ "Listing Comments"
      assert html =~ comment.body
    end

    test "saves new comment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Comment")
               |> render_click()
               |> follow_redirect(conn, ~p"/comments/new")

      assert render(form_live) =~ "New Comment"

      assert form_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#comment-form", comment: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/comments")

      html = render(index_live)
      assert html =~ "Comment created successfully"
      assert html =~ "some body"
    end

    test "updates comment in listing", %{conn: conn, comment: comment} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#comments-#{comment.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/comments/#{comment}/edit")

      assert render(form_live) =~ "Edit Comment"

      assert form_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#comment-form", comment: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/comments")

      html = render(index_live)
      assert html =~ "Comment updated successfully"
      assert html =~ "some updated body"
    end

    test "deletes comment in listing", %{conn: conn, comment: comment} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert index_live |> element("#comments-#{comment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#comments-#{comment.id}")
    end
  end

  describe "Show" do
    setup [:create_comment]

    test "displays comment", %{conn: conn, comment: comment} do
      {:ok, _show_live, html} = live(conn, ~p"/comments/#{comment}")

      assert html =~ "Show Comment"
      assert html =~ comment.body
    end

    test "updates comment and returns to show", %{conn: conn, comment: comment} do
      {:ok, show_live, _html} = live(conn, ~p"/comments/#{comment}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/comments/#{comment}/edit?return_to=show")

      assert render(form_live) =~ "Edit Comment"

      assert form_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#comment-form", comment: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/comments/#{comment}")

      html = render(show_live)
      assert html =~ "Comment updated successfully"
      assert html =~ "some updated body"
    end
  end
end
