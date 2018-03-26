use Mix.Config

config :logger, level: :warn

config :fs_server,
  file_reader: LogForwarder.Test.FileMock,
  use_file_watcher: false
