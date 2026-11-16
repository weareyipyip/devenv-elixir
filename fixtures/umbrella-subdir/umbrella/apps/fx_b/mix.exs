defmodule FxB.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_b,
      version: "0.0.0+development",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      deps: [{:fx_a, in_umbrella: true}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
