defmodule LogForwarder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    log_dir = System.get_env("LOG_DIR") || "/tmp/logs"
    remote = System.get_env("REMOTE") || "stats@localhost"

    # List all child processes to be supervised
    children = [
      worker(LogForwarder.Forwarder, [remote, [name: LogForwarder.Forwarder]]),
      worker(LogForwarder.FsServer, [log_dir, LogForwarder.Forwarder]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LogForwarder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
