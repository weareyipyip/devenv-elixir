defmodule FxProd do
  def check do
    actual = %{
      vsn: to_string(Application.spec(:fx_prod, :vsn)),
      env: Application.get_env(:fx_prod, :env),
      runtime: Application.get_env(:fx_prod, :runtime),
      env_sh: System.get_env("FX_ENV_SH"),
      overlay: File.exists?(Path.join(System.fetch_env!("RELEASE_ROOT"), "overlay.txt"))
    }

    expected = %{vsn: "1.2.3", env: "prod", runtime: "runtime", env_sh: "yes", overlay: true}
    if actual == expected, do: "ok", else: inspect(actual)
  end
end
