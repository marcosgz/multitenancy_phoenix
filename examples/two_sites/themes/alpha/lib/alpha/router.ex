defmodule Themes.Alpha.Router do
  use Themes.Alpha, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Themes.Alpha.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Themes.Alpha do
    pipe_through :browser

    get "/", PageController, :home

    live_session :alpha, on_mount: [Multitenancy.LiveView] do
      live "/counter", CounterLive
    end
  end
end
