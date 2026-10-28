defmodule <%= @module %>.Gettext do
  use Gettext.Backend, otp_app: :<%= @app %>, priv: "themes/<%= @name %>/priv/gettext"
end
