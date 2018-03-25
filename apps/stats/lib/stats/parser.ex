defmodule Stats.Parser do
  @mission_start 0
  @hit 1
  @damage 2
  @kill 3
  @player_despawn 4
  @takeoff 5
  @landing 6
  @mission_end 7
  @mission_objective 8
  @airfield_info 9
  @player_spawn 10
  @group_init 11
  @object_spawned 12
  # Unused?
  # @influence_area_header 13
  # @influence_area_boundary 14
  @log_version 15
  @bot_uninit 16
  # Unused?
  # @pos_changed 17
  @bot_eject_leave 18
  # Unused?
  # @round_end 19
  @join 20
  @leave 21

  def parse_event(line) do
    with {:ok, tokens, _} <- line |> to_charlist() |> :lexer.string(),
         {:ok, entry} <- :parser.parse(tokens),
         {atype, values} <- entry
                            |> Enum.into(%{}, &convert_field/1)
                            |> Map.pop(:atype) do
      parse(atype, values)
    else
      _ -> :error
    end
  end

  def parse_file(path) do
    File.stream!(path)
    # |> Stream.take(20)
    |> Stream.each(&IO.puts/1)
    |> Enum.map(&parse_event/1)
  end

  defp parse(_atype = @mission_start, values) do
    struct!(Stats.Events.MissionStart, values)
  end

  defp parse(_atype = @hit, values) do
    struct!(Stats.Events.Hit, values)
  end

  defp parse(_atype = @damage, values) do
    struct!(Stats.Events.Damage, values)
  end

  defp parse(_atype = @kill, values) do
    struct!(Stats.Events.Kill, values)
  end

  defp parse(_atype = @player_despawn, values) do
    struct!(Stats.Events.PlayerDespawn, values)
  end

  defp parse(_atype = @takeoff, values) do
    struct!(Stats.Events.Takeoff, values)
  end

  defp parse(_atype = @landing, values) do
    struct!(Stats.Events.Landing, values)
  end

  defp parse(_atype = @mission_end, values) do
    struct!(Stats.Events.MissionEnd, values)
  end

  defp parse(_atype = @mission_objective, values) do
    struct!(Stats.Events.MissionObjective, values)
  end

  defp parse(_atype = @airfield_info, values) do
    struct!(Stats.Events.AirfieldInfo, values)
  end

  defp parse(_atype = @player_spawn, values) do
    struct!(Stats.Events.PlayerSpawn, values)
  end

  defp parse(_atype = @group_init, values) do
    struct!(Stats.Events.GroupInit, values)
  end

  defp parse(_atype = @object_spawned, values) do
    struct!(Stats.Events.ObjectSpawned, values)
  end

  defp parse(_atype = @log_version, values) do
    struct!(Stats.Events.LogVersion, values)
  end

  defp parse(_atype = @bot_uninit, values) do
    struct!(Stats.Events.BotUninit, values)
  end

  defp parse(_atype = @bot_eject_leave, values) do
    struct!(Stats.Events.BotEjectLeave, values)
  end

  defp parse(_atype = @join, values) do
    struct!(Stats.Events.Join, values)
  end

  defp parse(_atype = @leave, values) do
    struct!(Stats.Events.Leave, values)
  end

  defp convert_field({k, v}) do
    if is_list(v) && List.ascii_printable?(v) do
      {k, String.trim(to_string(v))}
    else
      {k, v}
    end
  end
end
