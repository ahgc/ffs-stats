defmodule Stats.Mission do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def register_log_entries(server, entries) do
    entries
    |> Stream.map(&Stats.Parser.parse_event/1)
    |> Enum.each(&register_event(server, &1))

    # TODO: sane return value
  end

  def register_log_entry(server, entry) do
    entry
    |> Stats.Parser.parse_event
    |> register_event(server)
  end

  def register_event(server, event) do
    GenServer.cast(server, {:event, event})
  end

  def get_flights(server) do
    GenServer.call(server, {:get_flights})
  end

  def get_mission_details(server) do
    GenServer.call(server, {:get_mission_details})
  end

  def init(_) do
    {:ok, %{
        flights: %{},
        refs: %{},
     }}
  end

  def handle_call({:get_flights}, _from, mission) do
    {:reply, mission.flights, mission}
  end

  def handle_call({:get_mission_details}, _from, mission) do
    details = Map.drop(mission, [:flights, :refs])
    {:reply, details, mission}
  end

  def handle_cast({:event, event}, mission) do
    {:noreply, handle_event(mission, event)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, mission) do
    id = get_in(mission, [:refs, ref])
    new_state = mission
    |> Map.update(:refs, %{}, &Map.delete(&1, ref))
    |> Map.update(:flights, %{}, &Map.delete(&1, id))

    {:noreply, new_state}
  end

  defp dispatch_to_flight(mission, id, event) do
    case Map.fetch(mission[:flights], id) do
      {:ok, flight} -> Stats.Flight.register_event(flight, event); :ok
      :error -> Logger.warn("Flight #{id} not found"); :error
    end
  end

  defp handle_event(mission, event = %Stats.Events.MissionStart{}) do
    mission
    |> Map.put(:start_date, event.gdate)
    |> Map.put(:start_time, event.gtime)
    |> Map.put(:mfile, event.mfile)
  end

  defp handle_event(mission, event = %Stats.Events.Hit{}) do
    dispatch_to_flight(mission, event.aid, event)
    dispatch_to_flight(mission, event.tid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.Damage{}) do
    dispatch_to_flight(mission, event.aid, event)
    dispatch_to_flight(mission, event.tid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.Kill{}) do
    dispatch_to_flight(mission, event.aid, event)
    dispatch_to_flight(mission, event.tid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.PlayerSpawn{}) do
    id = event.plid

    {:ok, pid} = DynamicSupervisor.start_child(
      Stats.FlightSupervisor, {Stats.Flight, event})

    ref = Process.monitor(pid)

    mission
    |> put_in([:refs, ref], id)
    |> put_in([:flights, id], pid)
  end

  defp handle_event(mission, event = %Stats.Events.PlayerDespawn{}) do
    dispatch_to_flight(mission, event.plid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.Takeoff{}) do
    dispatch_to_flight(mission, event.pid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.Landing{}) do
    dispatch_to_flight(mission, event.pid, event)
    mission
  end

  defp handle_event(mission, event = %Stats.Events.MissionEnd{}) do
    mission
    |> Map.put(:duration, event.t)
  end

  defp handle_event(mission, _event) do
    IO.puts("UNHANDLED EVENT #{inspect(_event)}")
    mission
  end
end
