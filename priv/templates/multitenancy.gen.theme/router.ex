defmodule <%= @module %>.Router do
  @moduledoc "Routes of the <%= @name %> theme."

  use <%= @module %>, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {<%= @module %>.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", <%= @module %> do
    pipe_through :browser

    get "/", PageController, :home
<%= if @live do %>
    live_session :<%= @name %>, on_mount: [Multitenancy.LiveView] do
      live "/counter", CounterLive
    end
<% end %>  end
end
