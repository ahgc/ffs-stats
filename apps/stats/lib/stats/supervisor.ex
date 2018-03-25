defmodule Stats.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: Stats.FlightSupervisor, strategy: :one_for_one},
      {Stats.Mission, name: Stats.Mission},
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
