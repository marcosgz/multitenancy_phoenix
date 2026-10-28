defmodule Multitenancy.Site do
  @moduledoc "A site served by the application, bound to a theme and a set of hosts."

  @enforce_keys [:slug, :theme]
  defstruct [:slug, :theme, :locale, hosts: [], settings: %{}]

  @type t :: %__MODULE__{
          slug: String.t(),
          theme: Multitenancy.Theme.t(),
          locale: String.t() | nil,
          hosts: [String.t()],
          settings: map
        }
end
