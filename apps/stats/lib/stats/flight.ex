defmodule Stats.Flight do
  use GenServer, restart: :temporary

  def start_link(event = %Stats.Events.PlayerSpawn{}, opts \\ []) do
    # {event, opts} = Keyword.pop(opts, :event, %{})
    GenServer.start_link(__MODULE__, {:ok, event}, opts)
  end

  def register_event(flight, event) do
    GenServer.cast(flight, {:event, event})
  end

  def get(flight) do
    GenServer.call(flight, {:get})
  end

  def init({:ok, event = %Stats.Events.PlayerSpawn{}}) do
    {:ok, %{
        id: event.plid,

        # loadout fields
        type: event.type,
        skin: event.skin,
        payload: event.payload,
        init_bullets: event.bul,
        init_shells: event.sh,
        init_rockets: event.rct,
        init_bombs: event.bomb,
        init_fuel: event.fuel,

        country: event.country,
        init_field: event.field,
        inair: event.inair != 1,

        init_pos: event.pos,
        init_time: event.t,

        takeoffs: [],
        landings: [],

        hits_dealt: [],
        hits_received: [],

        damage_dealt: [],
        damage_received: [],

        kills: [],
     }
    }
  end

  def handle_call({:get}, _from, flight) do
    {:reply, flight, flight}
  end

  def handle_cast({:event, event}, flight) do
    {:noreply, handle_event(flight, event)}
  end

  defp handle_event(flight, event = %Stats.Events.Hit{}) do
    if event.aid == flight.id do
      Map.update(flight, :hits_dealt, [], &[event | &1])
    else
      Map.update(flight, :hits_received, [], &[event | &1])
    end
  end

  defp handle_event(flight, event = %Stats.Events.Damage{}) do
    if event.aid == flight.id do
      Map.update(flight, :damage_dealt, [], &[event | &1])
    else
      Map.update(flight, :damage_received, [], &[event | &1])
    end
  end

  defp handle_event(flight, event = %Stats.Events.Kill{}) do
    if event.aid == flight.id do
      Map.update(flight, :kills, [], &[event | &1])
    else
      Map.put(flight, :killed, event)
    end
  end

  defp handle_event(flight, event = %Stats.Events.PlayerDespawn{}) do
    flight
    |> Map.put(:final_time, event.t)
    |> Map.put(:final_bullets, event.bul)
    |> Map.put(:final_shells, event.sh)
    |> Map.put(:final_rockets, event.rct)
    |> Map.put(:final_bombs, event.bomb)
    |> Map.put(:final_pos, event.pos)
  end

  defp handle_event(flight, event = %Stats.Events.Takeoff{}) do
    Map.update(flight, :takeoffs, [], &[{event.t, event.pos} | &1])
  end

  defp handle_event(flight, event = %Stats.Events.Landing{}) do
    Map.update(flight, :landings, [], &[{event.t, event.pos} | &1])
  end
end
