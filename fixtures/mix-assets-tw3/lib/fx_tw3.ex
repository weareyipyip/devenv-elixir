defmodule FxTw3 do
  @html ~s(<div class="flex"></div>)
  def html, do: @html

  def check do
    css = File.read!(Application.app_dir(:fx_tw3, "priv/static/assets/app.css"))
    if String.contains?(css, ".flex{display:flex}"), do: "ok", else: css
  end
end
