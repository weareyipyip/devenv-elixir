defmodule FxRoot do
  def check do
    actual = %{
      vsn: to_string(Application.spec(:fx_root, :vsn)),
      erl: :fx_root_erl.hello(),
      compile: Application.get_env(:fx_root, :compile),
      extra: Application.get_env(:fx_root, :extra),
      env: Application.get_env(:fx_root, :env),
      runtime: Application.get_env(:fx_root, :runtime),
      json: Jason.encode!(%{a: 1}),
      telemetry: Application.spec(:telemetry, :vsn) != nil
    }

    expected = %{vsn: "1.2.3", erl: :ok, compile: "config", extra: "extra", env: "deploy", runtime: "releases", json: ~s({"a":1}), telemetry: true}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
