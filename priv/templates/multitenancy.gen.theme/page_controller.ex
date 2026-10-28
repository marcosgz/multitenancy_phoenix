defmodule <%= @module %>.PageController do
  use <%= @module %>, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
