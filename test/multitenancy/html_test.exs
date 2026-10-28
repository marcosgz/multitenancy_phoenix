defmodule Multitenancy.HTMLTest do
  use ExUnit.Case, async: true

  defp render(module, template) do
    apply(module, template, [%{}]) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  test "renders the theme template when it is overridden" do
    assert render(Themes.Fixture.PageHTML, :home) =~ ~s(<div class="theme">theme home</div>)
  end

  test "compiles missing templates from the base within the theme context" do
    assert render(Themes.Fixture.PageHTML, :show) =~ ~s(<div class="theme">base show</div>)
  end

  test "keeps the base module untouched" do
    assert render(Fixture.PageHTML, :home) =~ ~s(<div class="base">base home</div>)
  end

  test "does not require recompilation while templates are unchanged" do
    refute Themes.Fixture.PageHTML.__mix_recompile__?()
  end
end
