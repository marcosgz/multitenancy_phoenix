defmodule Multitenancy.ControllerTest do
  use ExUnit.Case, async: true

  test "theme_view/2 maps a base view to the theme one when defined" do
    assert Multitenancy.Controller.theme_view(Themes.Fixture, Fixture.PageHTML) == Themes.Fixture.PageHTML
  end

  test "theme_view/2 keeps the base view when the theme does not define it" do
    assert Multitenancy.Controller.theme_view(Themes.Fixture, Fixture.Layouts) == Themes.Fixture.Layouts
    assert Multitenancy.Controller.theme_view(Themes.Fixture, Fixture.PageController) == Fixture.PageController
  end
end
