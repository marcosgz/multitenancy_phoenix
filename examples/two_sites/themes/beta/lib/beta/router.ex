defmodule Themes.Beta.Router do
  use Themes.Beta, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Themes.Beta.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Themes.Beta do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about

    live_session :beta, on_mount: [Multitenancy.LiveView] do
      live "/counter", CounterLive
    end
  end
end
