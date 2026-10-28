defmodule Multitenancy.Locale do
  @moduledoc false

  @compile {:no_warn_undefined, Gettext}

  def put(%{locale: nil}), do: :ok

  def put(%{locale: locale}) do
    if Code.ensure_loaded?(Gettext), do: Gettext.put_locale(locale)
    :ok
  end
end
