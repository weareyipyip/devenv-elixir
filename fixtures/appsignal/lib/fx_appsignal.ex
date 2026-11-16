defmodule FxAppsignal do
  def check do
    agent = Path.join(:code.priv_dir(:appsignal), "appsignal-agent")
    actual = %{nif: Appsignal.Nif.loaded?(), agent: File.exists?(agent)}
    if actual == %{nif: true, agent: true}, do: "ok", else: inspect(actual)
  end
end
