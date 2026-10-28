defmodule Multitenancy.SiteResolver.YAMLTest do
  use ExUnit.Case

  alias Multitenancy.SiteResolver.YAML

  @moduletag :tmp_dir

  defp write(dir, content) do
    path = Path.join(dir, "sites.yml")
    File.write!(path, content)
    path
  end

  test "resolves every host of a site and merges theme settings", %{tmp_dir: dir} do
    dir
    |> write("""
    acme:
      theme: fixture
      locale: pt
      hosts: [acme.test, www.acme.test]
      settings:
        nested:
          color: blue
    """)
    |> YAML.load!()

    assert {:ok, site} = YAML.resolve("www.acme.test")
    assert {:ok, ^site} = YAML.resolve("acme.test")
    assert site.slug == "acme"
    assert site.locale == "pt"
    assert site.theme.module == Themes.Fixture
    assert site.settings == %{"title" => "Fixture", "nested" => %{"color" => "blue", "size" => 10}}
    assert :error = YAML.resolve("other.test")
    assert [%{slug: "acme"}] = YAML.sites()
  end

  test "the theme defaults to the site slug", %{tmp_dir: dir} do
    dir |> write("fixture:\n  hosts: fixture.test\n") |> YAML.load!()

    assert {:ok, %{theme: %{name: "fixture"}, hosts: ["fixture.test"]}} = YAML.resolve("fixture.test")
  end

  test "raises when a site points to an unknown theme", %{tmp_dir: dir} do
    path = write(dir, "acme:\n  theme: nope\n  hosts: [acme.test]\n")

    assert_raise Multitenancy.ThemeNotFoundError, fn -> YAML.load!(path) end
  end

  test "start_link/1 loads the file and is ignored by the supervisor", %{tmp_dir: dir} do
    path = write(dir, "fixture:\n  hosts: [boot.test]\n")

    assert :ignore = YAML.start_link(path: path)
    assert {:ok, _} = YAML.resolve("boot.test")
  end
end
