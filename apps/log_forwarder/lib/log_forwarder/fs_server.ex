defmodule LogForwarder.FsServer do
  @moduledoc """
  The `LogForwarder.FsServer` module watches a log directory for changes and
  enqueues new log entries to be sent to a remote stats server in order.
  """

  use GenServer

  require Logger

  @type log_pointer :: {String.t, non_neg_integer, non_neg_integer}

  # Will store the last file and line read in the log directory with this name.
  @state_file_name ".ffs_stats_log_forwarder_head"

  @doc """
  Start a linked `GenServer` that watches the specified `log_dir` for new logs.
  """
  @spec start_link(String.t, [term]) :: GenServer.on_start
  def start_link(log_dir, opts \\ []) do
    GenServer.start_link(__MODULE__, log_dir, opts)
  end

  @doc """
  `GenServer.init` callback.

  Reads the log head from disk (either the store state file or the most recent
  log stamp) configures the FS watcher for the specified `log_dir`.
  """
  @spec init(String.t) :: {:ok, map}
  def init(log_dir) do
    {head_stamp, head_idx, head_line} = log_head(log_dir)


    Logger.info("Initializing FsServer at #{log_name(head_stamp, head_idx)}@#{head_line}")

    # TODO: I'm not sure how to make this process wait for the forwarder to
    # start up so sleeping is the right way to fix that, right? Right? Guys?
    # (I'm so, so sorry.)
    Process.sleep(1000)

    # Initialize the state and go ahead and read any available lines.
    state = %{
        log_dir: log_dir,
        log_pointer: {head_stamp, head_idx, head_line}
    }
    |> read_lines()

    # Now that we're caught up, configure the filesystem watcher.
    :fs.start_link(:fs_watcher, log_dir)
    :fs.subscribe(:fs_watcher)

    {:ok, state}
  end

  @doc """
  `GenServer.handle_info` callback for `:fs` events.

  Note that each event type for the specified `path` is processed independently.
  """
  @spec handle_info({pid,
                    {:fs, :file_event},
                    {String.t, [atom]}}, map) :: {:noreply, map}
  def handle_info({_pid, {:fs, :file_event}, {path, events}}, state) do
    new_state = Enum.reduce(events, state, &process_event(&2, path, &1))
    {:noreply, new_state}
  end

  # Read the log head state from disk, or return `nil` if the file doesn't
  # exist.
  @spec read_state_file(String.t) :: nil | log_pointer
  defp read_state_file(log_dir) do
    path = Path.join(log_dir, @state_file_name)
    if File.exists?(path) do
      File.read!(path)
      |> :erlang.binary_to_term()
    else
      nil
    end
  end

  # Right the log head state to the pointer file in the log directory.
  @spec write_state_file(map) :: :ok | {:error, File.posix}
  defp write_state_file(state) do
    path = Path.join(state.log_dir, @state_file_name)
    File.write(path, :erlang.term_to_binary(state.log_pointer))
  end

  # Calculate the current log head using the file if it exists or by examining
  # the logs in the log directory if it does not.
  @spec log_head(String.t) :: log_pointer
  defp log_head(path) do
    case read_state_file(path) do
      nil -> log_head_from_files(path)
      ptr -> ptr
    end
  end

  # Calculate the log head from the file names in the log directory.
  @spec log_head_from_files(String.t) :: log_pointer
  defp log_head_from_files(path) do
    # get_files_for_mission here returns a sorted list of {stamp,idx} tuples for
    # the most recent mission timestamp. Therefore, we'll be starting at the
    # first line of the first file for the most recent mission.
    {head_stamp, head_file_idx} =
      get_files_for_mission(path, nil)
      |> List.first()

    {head_stamp, head_file_idx, 0}
  end

  # Return a list of logs in increasing time order in the specified `log_dir`
  # that have the specified `stamp` timestamp, or the most recent timestamp if
  # `stamp` is `nil`.
  @spec get_files_for_mission(String.t, nil | String.t) ::
        [{String.t, non_neg_integer}]
  defp get_files_for_mission(log_dir, head_stamp) do
    {:ok, files} = File.ls(log_dir)

    head_stamp_filter = fn {stamp, _} ->
      is_nil(head_stamp) or stamp == head_stamp
    end

    files
    |> Stream.map(&parse_log_name/1)
    # Parsing can fail if the file name doesn't match, so filter those out
    |> Stream.filter(fn v -> v != :error end)
    |> Stream.filter(head_stamp_filter)
    |> Enum.sort(&file_stamp_comparator/2)
  end

  # Parse the name of the file at `path` as a log name into its timestamp and
  # index, or return `:error` if the pattern doesn't match
  @spec parse_log_name(String.t) :: :error | {String.t, non_neg_integer}
  defp parse_log_name(path) do
    name = Path.basename(path)

    # Logs names have a format like:
    #   missionReport(YYYY-MM-DD_HH-MM-SS)[NNN].txt
    # Run a regex to extract the timestamp and the index (NNN)
    with parts <- Regex.run(~r/missionReport\((.*)\)\[(\d*)\]\.txt/, name),
         # The first list entry is the whole matched string, so strip that off
         {stamp, idx_str} <- parts |> tl() |> List.to_tuple(),
         {idx, _} = Integer.parse(idx_str)
    do
      {stamp, idx}
    else
      _ -> :error
    end
  end

  # Compare the timestamp and index of two logs. Sort them by decreasing stamp
  # but increasing index.
  @spec file_stamp_comparator({String.t, non_neg_integer},
                              {String.t, non_neg_integer}) :: boolean
  defp file_stamp_comparator({lhs_stamp, lhs_idx}, {rhs_stamp, rhs_idx}) do
      if rhs_stamp == lhs_stamp do
        lhs_idx < rhs_idx
      else
        rhs_stamp < lhs_stamp
      end
  end

  # Construct a log name from the specified `stamp` and `idx`.
  @spec log_name(String.t, non_neg_integer) :: String.t
  defp log_name(stamp, idx) do
    "missionReport(#{stamp})[#{idx}].txt"
  end

  # Construct the full path to a log in `log_dir` with the specified `stamp` and
  # `idx`.
  @spec log_path(String.t, String.t, non_neg_integer) :: String.t
  defp log_path(log_dir, stamp, idx) do
    Path.join(log_dir, log_name(stamp, idx))
  end

  # Handle an event in which we encounter a new mission stamp.
  # TODO: figure out what to do here
  @spec handle_new_stamp(map, String.t, non_neg_integer) :: map
  defp handle_new_stamp(state, stamp, idx) do
    IO.puts("NEW STAMP #{stamp}@#{idx}")
    state
  end

  # @spec handle_new_log(map, non_neg_integer) :: map
  # defp handle_new_log(state, idx) do
  #   {_, current_idx, _} = state.log_pointer

  #   update_idx_and_read = fn(idx, s) ->
  #     Map.update!(
  #       s, :log_pointer, fn {stamp, _, _} -> {stamp, idx, 0} end)
  #     |> read_lines()
  #   end

  #   state
  #   |> read_lines()
  #   |> (&Enum.reduce((current_idx+1)..idx, &1, update_idx_and_read)).()
  # end

  # Read any and all available log lines starting from the current head.
  @spec read_lines(map) :: map
  defp read_lines(state) do
    log_dir = state.log_dir
    {stamp, log_idx, head_line} = state.log_pointer

    # Open the current head log file, drop the lines we've already read, and get
    # a list of the remaining lines.
    batch = log_path(log_dir, stamp, log_idx)
    |> File.stream!()
    |> Stream.drop(head_line)
    |> Enum.to_list()

    # Enqueue the messages if we found any.
    if length(batch) > 0 do
      Logger.info("Enqueuing #{length(batch)} entries from #{log_name(stamp, log_idx)} at #{head_line}")

      :ok =
        LogForwarder.Forwarder.enqueue_log_batch(LogForwarder.Forwarder, batch)
    end

    cond do
      # If the next file exists, update the log pointer to start at the
      # beginning of the next file, and recursively read that file.
      File.exists?(log_path(log_dir, stamp, log_idx + 1)) ->
        Map.put(state, :log_pointer, {stamp, log_idx + 1, 0})
        |> read_lines()
      # If the next file doesn't exist and we read some lines, update the log
      # pointer for this file, write out the state, and return.
      length(batch) > 0 ->
        new_len = head_line + length(batch)
        new_state = Map.put(state, :log_pointer, {stamp, log_idx, new_len})
        write_state_file(new_state)
        new_state
      # If we read no lines, just return the unmodified state. This can happen
      # when, for example, we get duplicate events for a log file and the second
      # event has nothing left to read.
      true -> state
    end
  end

  # If we've receieved a FS event for the current mission, read any available
  # lines. Otherwise, handle the case where we've started a new mission.
  @spec read_updates(map, String.t, non_neg_integer) :: map
  defp read_updates(state, stamp, idx) do
    {head_stamp, _, _} = state.log_pointer

    cond do
      stamp != head_stamp -> handle_new_stamp(state, stamp, idx)
      true -> read_lines(state)
    end
  end

  # Process a `:modified` file system event by reading any available logs.
  @spec process_event(map, String.t, atom) :: map
  defp process_event(state, path, :modified) do
    case parse_log_name(path) do
      {stamp, idx} ->
        read_updates(state, stamp, idx)
      :error -> state
    end
  end

  # Default `process_event` handler for non-`:modified` filesystem actions.
  # @spec process_event(map, String.t, atom) :: map
  defp process_event(state, _path, _event) do
    # noop
    state
  end
end
