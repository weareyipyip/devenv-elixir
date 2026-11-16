import Config
config :fx_b, compile: "config"
import_config "#{config_env()}.exs"
