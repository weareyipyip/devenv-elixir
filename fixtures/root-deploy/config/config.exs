import Config
config :fx_root, compile: "config"
import_config "extra.exs"
import_config "#{config_env()}.exs"
