defmodule TwoSitesWeb.Sites.RoutingTest do
  use TwoSitesWeb.ConnCase, async: true

  defp on_host(conn, host), do: %{conn | host: host}

  describe "alpha.localtest.me" do
    test "renders the alpha home override within the alpha layout", %{conn: conn} do
      html = conn |> on_host("alpha.localtest.me") |> get(~p"/") |> html_response(200)

      assert html =~ "Alpha home override"
      assert html =~ "Fresh news from the alpha theme"
      assert html =~ "Alpha Daily"
      assert html =~ ~s(href="/themes/alpha/app.css")
      assert html =~ ~s(data-site="alpha")
      refute html =~ "Base home template"
    end

    test "does not serve beta-only routes", %{conn: conn} do
      conn = conn |> on_host("alpha.localtest.me") |> get("/about")

      assert html_response(conn, 404) =~ "Not Found"
    end
  end

  describe "beta.localtest.me" do
    test "falls back to the base home template rendered in the beta layout", %{conn: conn} do
      html = conn |> on_host("beta.localtest.me") |> get(~p"/") |> html_response(200)

      assert html =~ "Base home template"
      assert html =~ "Rendered by the beta theme"
      assert html =~ ~s(href="/themes/beta/app.css")
      assert html =~ ~s(href="/about")
      refute html =~ "alpha"
    end

    test "serves its theme-only page", %{conn: conn} do
      html = conn |> on_host("beta.localtest.me") |> get("/about") |> html_response(200)

      assert html =~ "About Beta"
    end
  end

  test "platform host is served by the base router", %{conn: conn} do
    html = conn |> on_host("localhost") |> get(~p"/") |> html_response(200)

    assert html =~ "Base home template"
    assert html =~ ~s(href="/assets/css/app.css")
    refute html =~ "Rendered by the"
  end

  test "unknown hosts get a 404", %{conn: conn} do
    conn = conn |> on_host("unknown.localtest.me") |> get("/")

    assert conn.status == 404
    assert conn.halted
  end
end
