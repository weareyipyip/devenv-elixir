defmodule FxTzdata.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_tzdata,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:tzdata, "~> 1.1"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
