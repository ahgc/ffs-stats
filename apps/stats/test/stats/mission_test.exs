defmodule Stats.MissionTest do
  use ExUnit.Case, async: false
  doctest Stats.Mission

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}
  end

  def spawn_event do
    %Stats.Events.PlayerSpawn{
      t: 42,
      plid: 1234,
      pid: 5678,
      bul: 1000,
      sh: 300,
      bomb: 2,
      rct: 8,
      pos: {100.0, 101.0, 102.0},
      ids: "0dd-c0ffee",
      login: "bad-f00d",
      name: "Goose",
      type: "F-14D",
      country: 101,
      form: 0,
      field: 16,
      inair: 1,
      parent: -1,
      payload: 64,
      fuel: 0.42,
      skin: "skins/tomcat/mig28_killer.skin",
      wm: 0,
    }
  end

  def target_spawn_event do
    %Stats.Events.PlayerSpawn{
      t: 43,
      plid: 1235,
      pid: 5679,
      bul: 1000,
      sh: 300,
      bomb: 2,
      rct: 8,
      pos: {100.0, 101.0, 102.0},
      ids: "fee1dead",
      login: "deadbeef",
      name: "Anonymous Mig-28 Pilot",
      type: "Mig-28A",
      country: 102,
      form: 0,
      field: 16,
      inair: 1,
      parent: -1,
      payload: 64,
      fuel: 0.42,
      skin: "skins/mig28/whocares.skin",
      wm: 0,
    }
  end

  setup context do
    _ = start_supervised!({Stats.Mission, name: context.test})
    %{server: context.test}
  end

  test "initialization", %{server: server} do
    flights = Stats.Mission.get_flights(server)
    assert map_size(flights) == 0
  end

  test "handle mission start", %{server: server} do
    event = %Stats.Events.MissionStart{
      t: 42,
      gdate: "Febtober 21, 1942",
      # TODO(brummel): this will break if we ever start parsing these as times
      gtime: "0-dark:30:00",
      mfile: "missions/best_ever.miz",
      gtype: 4,
      cntrs: "what is this",
      setts: "what is this, v2",
      mods: 7,
      preset: 8,
      aqmid: 9
    }

    Stats.Mission.register_event(server, event)
    details = Stats.Mission.get_mission_details(server)

    assert map_size(details) == 3
    assert details.start_date == event.gdate
    assert details.start_time == event.gtime
    assert details.mfile == event.mfile
  end

  test "handle player spawn", %{server: server} do
    event = spawn_event()
    Stats.Mission.register_event(server, event)

    flights = Stats.Mission.get_flights(server)
    assert map_size(flights) == 1

    assert Map.has_key?(flights, event.plid)

    flight = Stats.Flight.get(Map.fetch!(flights, event.plid))
    assert flight.id == event.plid
  end

  test "handle hit event", %{server: server} do
    plid = spawn_event().plid
    Stats.Mission.register_event(server, spawn_event())

    tid = target_spawn_event().plid
    Stats.Mission.register_event(server, target_spawn_event())

    event = %Stats.Events.Hit{
      t: 44,
      ammo: "BIGASS_GERMAN_SHELLS",
      aid: plid,
      tid: tid,
    }

    Stats.Mission.register_event(server, event)

    flights = Stats.Mission.get_flights(server)
    assert map_size(flights) == 2

    assert Map.has_key?(flights, plid)

    aid_flight = Stats.Flight.get(Map.fetch!(flights, plid))
    assert aid_flight.id == plid
    assert length(aid_flight.hits_dealt) == 1
    assert hd(aid_flight.hits_dealt) == event

    assert Map.has_key?(flights, tid)

    tid_flight = Stats.Flight.get(Map.fetch!(flights, tid))
    assert tid_flight.id == tid
    assert length(tid_flight.hits_received) == 1
    assert hd(tid_flight.hits_received) == event
  end
end
