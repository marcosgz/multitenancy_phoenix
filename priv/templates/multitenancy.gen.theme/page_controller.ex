defmodule <%= @module %>.PageController do
  @moduledoc "Pages of the <%= @name %> theme."

  use <%= @module %>, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
