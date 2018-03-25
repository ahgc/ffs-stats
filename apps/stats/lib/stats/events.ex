defmodule Stats.Events do
  @type coords :: {float, float, float}

  defmodule MissionStart do
    defstruct [
      :t,
      :gdate,
      :gtime,
      :mfile,
      :mid,
      :gtype,
      :cntrs,
      :setts,
      :mods,
      :preset,
      :aqmid
    ]
    @type t :: %MissionStart {
      t: non_neg_integer,
      gdate: String.t(),
      gtime: String.t(),
      mfile: String.t(),
      # mid: nil, TODO: what is this?
      gtype: integer,
      cntrs: String.t(),
      setts: String.t(),
      mods: integer,
      preset: integer,
      aqmid: integer,
    }
  end

  defmodule Hit do
    defstruct [:t, :ammo, :aid, :tid]
    @type t :: %Hit{
      t: non_neg_integer,
      ammo: String.t(),
      aid: non_neg_integer,
      tid: non_neg_integer
    }
  end

  defmodule Damage do
    defstruct [:t, :dmg, :aid, :tid, :pos]
    @type t :: %Damage{
      t: non_neg_integer,
      dmg: float,
      aid: non_neg_integer,
      tid: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule Kill do
    defstruct [:t, :aid, :tid, :pos]
    @type t :: %Kill{
      t: non_neg_integer,
      aid: non_neg_integer,
      tid: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule PlayerDespawn do
    defstruct [:t, :plid, :pid, :bul, :sh, :bomb, :rct, :pos]
    @type t :: %PlayerDespawn{
      t: non_neg_integer,
      plid: non_neg_integer,
      pid: non_neg_integer,
      bul: non_neg_integer,
      sh: non_neg_integer,
      bomb: non_neg_integer,
      rct: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule Takeoff do
    defstruct [:t, :pid, :pos]
    @type t :: %Takeoff{
      t: non_neg_integer,
      pid: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule Landing do
    defstruct [:t, :pid, :pos]
    @type t :: %Takeoff{
      t: non_neg_integer,
      pid: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule MissionEnd do
    defstruct [:t]
    @type t :: %MissionEnd{t: non_neg_integer}
  end

  defmodule MissionObjective do
    defstruct [:t, :objid, :pos, :coal, :type, :res, :ictype]
    @type t :: %MissionObjective{
      t: non_neg_integer,
      pos: Stats.Events.coords,
      coal: integer,
      type: integer,
      res: integer,
      ictype: integer
    }
  end

  defmodule AirfieldInfo do
    defstruct [:t, :aid, :country, :pos, :ids]
    @type t :: %AirfieldInfo{
      t: non_neg_integer,
      aid: non_neg_integer,
      country: non_neg_integer,
      pos: Stats.Events.coords,
      ids: list(integer),
    }
  end

  defmodule PlayerSpawn do
    defstruct [:t,
               :plid,
               :pid,
               :bul,
               :sh,
               :bomb,
               :rct,
               :pos,
               :ids,
               :login,
               :name,
               :type,
               :country,
               :form,
               :field,
               :inair,
               :parent,
               :payload,
               :fuel,
               :skin,
               :wm]
    @type t :: %PlayerSpawn{
      t: non_neg_integer,
      plid: non_neg_integer,
      pid: non_neg_integer,
      bul: non_neg_integer,
      sh: non_neg_integer,
      bomb: non_neg_integer,
      rct: non_neg_integer,
      pos: Stats.Events.coords,
      ids: String.t(),
      login: String.t(),
      name: String.t(),
      type: String.t(),
      country: non_neg_integer,
      form: non_neg_integer,
      field: non_neg_integer,
      inair: non_neg_integer,
      parent: integer,
      payload: non_neg_integer,
      fuel: float,
      skin: String.t(),
      wm: non_neg_integer,
    }
  end

  defmodule GroupInit do
    defstruct [:t, :gid, :ids, :lid]
    @type t :: %GroupInit{
      t: non_neg_integer,
      gid: non_neg_integer,
      ids: list(non_neg_integer),
      lid: non_neg_integer
    }
  end

  defmodule ObjectSpawned do
    defstruct [:t, :id, :type, :country, :name, :pid]
    @type t :: %ObjectSpawned{
      t: non_neg_integer,
      id: non_neg_integer,
      type: String.t(),
      country: non_neg_integer,
      name: String.t(),
      pid: integer,
    }
  end

  defmodule LogVersion do
    defstruct [:t, :ver]
    @type t :: %LogVersion{t: non_neg_integer, ver: non_neg_integer}
  end

  defmodule BotUninit do
    defstruct [:t, :botid, :pos]
    @type t :: %BotUninit{
      t: non_neg_integer,
      botid: non_neg_integer,
      pos: Stats.Events.coords
    }
  end

  defmodule BotEjectLeave do
    defstruct [:t, :botid, :parentid, :pos]
    @type t :: %BotEjectLeave{
      t: non_neg_integer,
      botid: non_neg_integer,
      parentid: non_neg_integer,
      pos: Stats.Events.coords,
    }
  end

  defmodule Join do
    defstruct [:t, :userid, :usernickid]
    @type t :: %Join{
      t: non_neg_integer,
      userid: String.t(),
      usernickid: String.t()
    }
  end

  defmodule Leave do
    defstruct [:t, :userid, :usernickid]
    @type t :: %Leave{
      t: non_neg_integer,
      userid: String.t(),
      usernickid: String.t()
    }
  end
end
