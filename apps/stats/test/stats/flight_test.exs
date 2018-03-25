defmodule Stats.FlightTest do
  use ExUnit.Case, async: true
  doctest Stats.Flight

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


  setup do
    event = spawn_event()

    child_spec = %{start: {Stats.Flight, :start_link, [event, []]}}
    flight = start_supervised!(Stats.Flight, child_spec)
    %{flight: flight}
  end

  test "initialization", %{flight: flight} do
    values = Stats.Flight.get(flight)

    spawn_event = spawn_event()

    assert values.id == spawn_event.plid

    assert values.type == spawn_event.type
    assert values.skin == spawn_event.skin
    assert values.payload == spawn_event.payload
    assert values.init_bullets == spawn_event.bul
    assert values.init_shells == spawn_event.sh
    assert values.init_bombs == spawn_event.bomb
    assert values.init_rockets == spawn_event.rct
    assert values.init_fuel == spawn_event.fuel

    assert values.country == spawn_event.country
    assert values.init_field == spawn_event.field
    assert values.inair == spawn_event.inair != 1

    assert values.init_pos == spawn_event.pos
    assert values.init_time == spawn_event.t

    assert values.takeoffs == []
    assert values.landings == []

    assert values.hits_dealt == []
    assert values.hits_received == []

    assert values.damage_dealt == []
    assert values.damage_received == []

    assert values.kills == []
  end

  test "hit other", %{flight: flight} do
    spawn_event = spawn_event()

    hit_event = %Stats.Events.Hit{
      t: 43,
      ammo: "BIGASS_GER_BULLETS",
      aid: spawn_event.plid,
      tid: 667408,
    }

    Stats.Flight.register_event(flight, hit_event)

    values = Stats.Flight.get(flight)

    assert values.hits_dealt == [hit_event]
    assert values.hits_received == []
  end

  test "got hit", %{flight: flight} do
    spawn_event = spawn_event()

    hit_event = %Stats.Events.Hit{
      t: 43,
      ammo: "BIGASS_RUS_BULLETS",
      aid: 667408,
      tid: spawn_event.plid,
    }

    Stats.Flight.register_event(flight, hit_event)

    values = Stats.Flight.get(flight)

    assert values.hits_dealt == []
    assert values.hits_received == [hit_event]
  end

  test "damaged other", %{flight: flight} do
    spawn_event = spawn_event()

    dmg_event = %Stats.Events.Damage{
      t: 43,
      aid: spawn_event.plid,
      tid: 271828,
      pos: {8772.89, 328269.65, 847273.83},
    }

    Stats.Flight.register_event(flight, dmg_event)

    values = Stats.Flight.get(flight)

    assert values.damage_dealt == [dmg_event]
    assert values.damage_received == []
  end

  test "got damaged", %{flight: flight} do
    spawn_event = spawn_event()

    dmg_event = %Stats.Events.Damage{
      t: 43,
      aid: 271828,
      tid: spawn_event.plid,
      pos: {8772.89, 826965.68, 847273.83},
    }

    Stats.Flight.register_event(flight, dmg_event)

    values = Stats.Flight.get(flight)

    assert values.damage_dealt == []
    assert values.damage_received == [dmg_event]
  end

  test "killed something", %{flight: flight} do
    spawn_event = spawn_event()

    kill_event = %Stats.Events.Kill{
      t: 43,
      aid: spawn_event.plid,
      tid: 602214,
      pos: {778966.84, 677569.89, 738352.5},
    }

    Stats.Flight.register_event(flight, kill_event)

    values = Stats.Flight.get(flight)

    assert values.kills == [kill_event]
    assert not Map.has_key?(values, :killed)
  end

  test "got killed", %{flight: flight} do
    spawn_event = spawn_event()

    kill_event = %Stats.Events.Kill{
      t: 43,
      aid: 602214,
      tid: spawn_event.plid,
      pos: {778966.84, 677569.89, 738352.5},
    }

    Stats.Flight.register_event(flight, kill_event)

    values = Stats.Flight.get(flight)

    assert values.kills == []
    assert values.killed == kill_event
  end

  test "takeoff", %{flight: flight} do
    takeoff_event = %Stats.Events.Takeoff{
      t: 43,
      pid: 42, # TODO: this should probably be checked before adding it...
      pos: {7879.84, 87798284.72, 6970707982.84},
    }

    Stats.Flight.register_event(flight, takeoff_event)

    values = Stats.Flight.get(flight)

    assert values.takeoffs == [{takeoff_event.t, takeoff_event.pos}]
  end

  test "landing", %{flight: flight} do
    landing_event = %Stats.Events.Landing{
      t: 43,
      pid: 42, # TODO: this should probably be checked before adding it...
      pos: {877265.84, 897985.68, 797378.71},
    }

    Stats.Flight.register_event(flight, landing_event)

    values = Stats.Flight.get(flight)

    assert values.landings == [{landing_event.t, landing_event.pos}]
  end

  test "player despawn", %{flight: flight} do
    spawn_event = spawn_event()

    despawn_event = %Stats.Events.PlayerDespawn{
      t: 43,
      plid: spawn_event.plid,
      pid: spawn_event.pid,
      bul: div(spawn_event.bul, 2),
      sh: div(spawn_event.sh, 2),
      rct: div(spawn_event.rct, 2),
      bomb: div(spawn_event.bomb, 2),
      pos: {11997.114, 66111.117, 769879.110},
    }

    Stats.Flight.register_event(flight, despawn_event)

    values = Stats.Flight.get(flight)

    assert values.final_time == despawn_event.t
    assert values.final_bullets == despawn_event.bul
    assert values.final_shells == despawn_event.sh
    assert values.final_rockets == despawn_event.rct
    assert values.final_bombs == despawn_event.bomb
    assert values.final_pos == despawn_event.pos
  end
end
