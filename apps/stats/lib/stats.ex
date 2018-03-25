defmodule Stats do
  use Application
  @moduledoc """
  Documentation for Stats.
  """

  def start(_type, _args) do
    Stats.Supervisor.start_link(name: Stats.Supervisor)
  end
end
