defmodule Mix.Tasks.Multitenancy.Gen.ThemeTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  end

  test "generates a theme skeleton", %{tmp_dir: dir} do
    File.cd!(dir, fn ->
      Mix.Tasks.Multitenancy.Gen.Theme.run(~w(my_store --web-module DemoWeb))

      root = "themes/my_store"

      for file <- ~w(my_store.ex my_store/router.ex my_store/layouts.ex my_store/page_html.ex my_store/counter_live.ex) do
        assert {:ok, _} = root |> Path.join("lib/#{file}") |> File.read!() |> Code.string_to_quoted()
      end

      assert File.read!("#{root}/lib/my_store.ex") =~ ~s(use Multitenancy.Theme, name: "my_store")
      assert File.read!("#{root}/lib/my_store/page_html.ex") =~ "base: DemoWeb.PageHTML"
      assert File.read!("#{root}/lib/my_store/router.ex") =~ ~s(live "/counter", CounterLive)
      assert File.read!("#{root}/lib/my_store/layouts/root.html.heex") =~ ~s(/themes/my_store/app.css)
      assert File.read!("#{root}/assets/css/app.css") =~ ~s(@import "tailwindcss")
      assert File.read!("#{root}/config/settings.yml") =~ "title: MyStore"
    end)
  end

  test "skips the LiveView with --no-live", %{tmp_dir: dir} do
    File.cd!(dir, fn ->
      Mix.Tasks.Multitenancy.Gen.Theme.run(~w(plain --no-live))

      refute File.exists?("themes/plain/lib/plain/counter_live.ex")
      refute File.read!("themes/plain/lib/plain/router.ex") =~ "live_session"
    end)
  end

  test "refuses to overwrite an existing theme", %{tmp_dir: dir} do
    File.cd!(dir, fn ->
      File.mkdir_p!("themes/taken")
      assert_raise Mix.Error, ~r/already exists/, fn -> Mix.Tasks.Multitenancy.Gen.Theme.run(~w(taken)) end
    end)
  end
end
