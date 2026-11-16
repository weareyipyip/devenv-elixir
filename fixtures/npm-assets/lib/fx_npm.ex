defmodule FxNpm do
  def check do
    js = File.read!(Application.app_dir(:fx_npm, "priv/static/assets/app.js"))
    if String.contains?(js, "fx-npm-marker"), do: "ok", else: js
  end
end
