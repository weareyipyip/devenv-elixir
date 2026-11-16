defmodule FxUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.0.0+development",
      deps: [],
      releases: [fx_umbrella: [applications: [fx_a: :permanent, fx_b: :permanent]]]
    ]
  end
end
