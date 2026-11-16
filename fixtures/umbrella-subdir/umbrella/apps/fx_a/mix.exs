defmodule FxA.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_a,
      version: "0.0.0+development",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      deps: [{:jason, "~> 1.4"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
