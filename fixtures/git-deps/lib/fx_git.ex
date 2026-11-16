defmodule FxGit do
  @icons Mix.Project.deps_paths()
         |> Map.fetch!(:heroicons)
         |> Path.join("24/outline/*.svg")
         |> Path.wildcard()
         |> length()

  def check do
    actual = %{json: Jason.encode!(%{a: 1}), icons: @icons > 100}
    expected = %{json: ~s({"a":1}), icons: true}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
