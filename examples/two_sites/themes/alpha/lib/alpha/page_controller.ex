defmodule Themes.Alpha.PageController do
  use Themes.Alpha, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
