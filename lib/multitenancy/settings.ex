defmodule Multitenancy.Settings do
  @moduledoc false

  def load_file(path) do
    if File.exists?(path) do
      path |> YamlElixir.read_from_file!() |> normalize()
    else
      %{}
    end
  end

  def normalize(nil), do: %{}
  def normalize(map) when is_map(map), do: map

  def deep_merge(left, right) do
    Map.merge(left, right, fn
      _key, %{} = l, %{} = r -> deep_merge(l, r)
      _key, _l, r -> r
    end)
  end
end
