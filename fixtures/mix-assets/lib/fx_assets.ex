defmodule FxAssets do
  @html ~s(<div class="flex"></div>)
  def html, do: @html

  def check do
    static = Application.app_dir(:fx_assets, "priv/static")
    manifest = static |> Path.join("cache_manifest.json") |> File.read!() |> Jason.decode!()
    read = fn file -> File.read!(Path.join(static, manifest["latest"][file])) end

    actual = %{
      css: String.contains?(read.("assets/app.css"), ".flex{display:flex}"),
      js: String.contains?(read.("assets/app.js"), "fx-assets-marker")
    }

    if actual == %{css: true, js: true}, do: "ok", else: inspect(actual)
  end
end
