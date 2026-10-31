defmodule Multitenancy.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Multitenancy.Plug.{Dispatch, ResolveSite}

  @resolve_opts [resolver: Fixture.StaticResolver, platform_hosts: ["platform.test"], platform_paths: ["/admin"]]

  defp request(host, path \\ "/", opts \\ @resolve_opts) do
    conn(:get, path)
    |> Map.put(:host, host)
    |> ResolveSite.call(ResolveSite.init(opts))
  end

  defp dispatch(conn) do
    if conn.halted,
      do: conn,
      else: Dispatch.call(conn, Dispatch.init(platform: Fixture.PlatformRouter, platform_paths: ["/admin"]))
  end

  test "assigns the resolved site and theme" do
    conn = request("fixture.test")

    assert conn.assigns.current_site.slug == "fixture"
    assert conn.assigns.current_theme.name == "fixture"
    refute conn.halted
  end

  test "halts unknown hosts with a 404" do
    conn = request("unknown.test")

    assert conn.halted
    assert conn.status == 404
  end

  test "leaves platform hosts unresolved" do
    conn = request("platform.test")

    refute conn.halted
    refute Map.has_key?(conn.assigns, :current_site)
  end

  test "dispatches site requests to the theme router and swaps the view" do
    conn = "fixture.test" |> request() |> dispatch()

    assert conn.private.phoenix_router == Themes.Fixture.Router
    assert conn.resp_body =~ ~s(<div class="theme">base show</div>)
  end

  test "dispatches platform requests to the platform router with the base view" do
    conn = "platform.test" |> request() |> dispatch()

    assert conn.private.phoenix_router == Fixture.PlatformRouter
    assert conn.resp_body =~ ~s(<div class="base">base show</div>)
  end

  test "theme routes are not visible to the platform" do
    assert_raise Phoenix.Router.NoRouteError, fn -> "platform.test" |> request("/theme-only") |> dispatch() end
    assert "fixture.test" |> request("/theme-only") |> dispatch() |> Map.get(:status) == 200
  end

  test "serves platform paths on unknown hosts" do
    conn = "unknown.test" |> request("/admin/status") |> dispatch()

    assert conn.status == 200
    assert conn.private.phoenix_router == Fixture.PlatformRouter
  end

  test "routes platform paths of a site to the platform router, keeping the site" do
    conn = "fixture.test" |> request("/admin/status") |> dispatch()

    assert conn.private.phoenix_router == Fixture.PlatformRouter
    assert conn.assigns.current_site.slug == "fixture"
  end

  test "platform paths match whole segments" do
    assert "unknown.test" |> request("/administrator") |> Map.get(:status) == 404
  end

  test "uses resolve_conn/1 when the resolver defines it" do
    conn =
      conn(:get, "/")
      |> Map.put(:host, "unknown.test")
      |> Plug.Conn.put_req_header("x-site", "fixture")
      |> ResolveSite.call(ResolveSite.init(resolver: Fixture.HeaderResolver, platform_hosts: []))

    assert conn.assigns.current_site.slug == "fixture"
  end
end
