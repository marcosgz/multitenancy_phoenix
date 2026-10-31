defmodule Multitenancy.Site do
  @moduledoc """
  A site served by the application, bound to a theme and a set of hosts.

  `:data` holds anything the application wants to carry along with the site,
  such as the database record it was resolved from.
  """

  @enforce_keys [:slug, :theme]
  defstruct [:slug, :theme, :locale, :data, hosts: [], settings: %{}]

  @type t :: %__MODULE__{
          slug: String.t(),
          theme: Multitenancy.Theme.t(),
          locale: String.t() | nil,
          hosts: [String.t()],
          settings: map,
          data: term
        }
end
