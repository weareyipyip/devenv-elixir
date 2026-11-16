defmodule FxRoot.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_root,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:jason, "~> 1.4"}, {:telemetry, "~> 1.3"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
