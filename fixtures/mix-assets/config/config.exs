import Config

config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.25.4",
  fx_assets: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "4.1.12",
  fx_assets: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("..", __DIR__)
  ]
