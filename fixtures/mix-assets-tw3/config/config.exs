import Config

config :tailwind,
  version: "3.4.17",
  fx_tw3: [
    args: ~w(--config=tailwind.config.js --input=css/app.css --output=../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]
