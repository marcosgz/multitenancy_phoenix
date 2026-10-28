defmodule TwoSitesWeb.Sites.CounterLiveTest do
  use TwoSitesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  for {host, slug, title} <- [
        {"alpha.localtest.me", "alpha", "Alpha Daily"},
        {"beta.localtest.me", "beta", "Beta"}
      ] do
    test "mounts and increments on #{host}", %{conn: conn} do
      {:ok, view, html} = live(%{conn | host: unquote(host)}, "/counter")

      assert html =~ unquote(title)
      assert html =~ ~s(data-site="#{unquote(slug)}")
      assert view |> element("#count") |> render() =~ ">0<"

      view |> element("#increment") |> render_click()

      assert view |> element("#count") |> render() =~ ">1<"
      assert render(view) =~ unquote(title)
    end
  end

  test "beta navigates between theme routes", %{conn: conn} do
    {:ok, view, _html} = live(%{conn | host: "beta.localtest.me"}, "/counter")

    assert {:error, {:live_redirect, %{to: "/about"}}} =
             view |> element("a", "About") |> render_click()
  end
end
