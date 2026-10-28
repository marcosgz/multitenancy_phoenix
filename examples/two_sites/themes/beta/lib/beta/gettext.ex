defmodule Themes.Beta.Gettext do
  use Gettext.Backend, otp_app: :two_sites, priv: "themes/beta/priv/gettext"
end
