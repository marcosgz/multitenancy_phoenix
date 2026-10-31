defmodule <%= @module %>.Gettext do
  @moduledoc "Gettext backend of the <%= @name %> theme."

  use Gettext.Backend, otp_app: :<%= @app %>, priv: "themes/<%= @name %>/priv/gettext"
end
