defmodule Themes.Alpha.Gettext do
  use Gettext.Backend, otp_app: :two_sites, priv: "themes/alpha/priv/gettext"
end
