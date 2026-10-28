defmodule MultitenancyTest do
  use ExUnit.Case, async: true

  test "theme_module/1 follows the Themes namespace" do
    assert Multitenancy.theme_module("my_store") == Themes.MyStore
  end

  test "theme/1 and theme!/1 load the theme definition" do
    assert {:ok, %Multitenancy.Theme{name: "fixture", router: Themes.Fixture.Router}} =
             Multitenancy.theme("fixture")

    assert :error = Multitenancy.theme("missing")
    assert_raise Multitenancy.ThemeNotFoundError, ~r/Themes.Missing/, fn -> Multitenancy.theme!("missing") end
  end

  test "theme settings are read from config/settings.yml" do
    assert Themes.Fixture.__theme__().settings == %{
             "title" => "Fixture",
             "nested" => %{"color" => "red", "size" => 10}
           }
  end

  @tag :tmp_dir
  test "theme_names/1 lists directories holding a lib folder", %{tmp_dir: dir} do
    for name <- ~w(beta alpha), do: File.mkdir_p!(Path.join([dir, name, "lib"]))
    File.mkdir_p!(Path.join(dir, "not_a_theme"))

    assert Multitenancy.theme_names(dir) == ~w(alpha beta)
  end
end
