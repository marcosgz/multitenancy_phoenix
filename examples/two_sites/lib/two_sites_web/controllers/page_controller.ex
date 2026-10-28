defmodule TwoSitesWeb.PageController do
  use TwoSitesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
