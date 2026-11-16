defmodule FxB do
  def check do
    actual = %{
      vsn_a: to_string(Application.spec(:fx_a, :vsn)),
      vsn_b: to_string(Application.spec(:fx_b, :vsn)),
      compile: Application.get_env(:fx_b, :compile),
      env: Application.get_env(:fx_b, :env),
      runtime: Application.get_env(:fx_b, :runtime),
      json: FxA.json()
    }

    expected = %{vsn_a: "1.2.3", vsn_b: "1.2.3", compile: "config", env: "deploy", runtime: "runtime", json: ~s({"a":1})}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
