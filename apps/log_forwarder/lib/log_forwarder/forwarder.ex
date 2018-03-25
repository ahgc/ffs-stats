defmodule LogForwarder.Forwarder do
  @moduledoc """
  The `LogForwarder.Forwarder` module keeps a queue of log message batches and
  sends them to the Stats.Mission server via RPCs.
  """

  use GenServer

  alias :queue, as: Queue

  require Logger

  # Async send task interval, in ms
  @send_interval 1000

  @doc """
  Start a linked `GenServer` that sends queued logs to the specified `remote`.
  """
  @spec start_link(String.t, [term]) :: GenServer.on_start
  def start_link(remote, opts \\ []) do
    GenServer.start_link(__MODULE__, remote, opts)
  end

  @doc """
  `GenServer.init` callback.

  Configures the forwarder with an empty queue and to send logs to the specified
  `remote`.
  """
  @spec init(String.t) :: {:ok, map}
  def init(remote) do
    schedule_send()

    {:ok, %{
        remote: String.to_atom(remote),
        buffer: Queue.new()
     }}
  end

  @doc """
  Stop the specified `server`.
  """
  @spec stop(GenServer.server) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @doc """
  Add the specified list of log strings, `batch`, to the end of queue to be sent
  to the Stats server.
  """
  @spec enqueue_log_batch(GenServer.server, [String.t]) :: term
  def enqueue_log_batch(server, batch) do
    GenServer.call(server, {:enqueue, batch})
  end

  @doc """
  Handle a request to enqueue a list of log strings, `batch`.

  Return the `:ok` to the caller.
  """
  @spec handle_call({:enqueue, [String.t]}, term, map) :: {:reply, :ok, map}
  def handle_call({:enqueue, batch}, _from, state) do
    new_state = Map.update!(state, :buffer, &Queue.in(batch, &1))
    {:reply, :ok, new_state}
  end

  @doc """
  Periodic callback to try and send a batch of logs to the stat server.

  Reschedules the timer task regardless of success.
  """
  @spec handle_info(:send_logs, map) :: {:noreply, map}
  def handle_info(:send_logs, state) do
    new_state = Map.update!(state, :buffer, &send_logs(state, &1))
    schedule_send()
    {:noreply, new_state}
  end

  # Pop a list of logs off of the queue, if any, and send it to the remote. If
  # the logs were successfully sent, return the new queue. Otherwise, return the
  # original queue unmodified.
  @spec send_logs(map, Queue.queue) :: Queue.queue
  defp send_logs(state, queue) do
    with {{:value, logs}, remaining} <- Queue.out(queue),
         :ok <- send_batch(state, logs) do
      remaining
    else
      :error -> queue
      {:empty, remaining} -> remaining
    end
  end

  # Send a list of log strings, `logs`, via RPC to the remote stats server.
  # Return `:ok` on success, or `:error` otherwise.
  @spec send_batch(map, [String.t]) :: :ok | :error
  defp send_batch(state, logs) do
    remote = state.remote
    args = [Stats.Mission, logs]

    Logger.info("Sending #{length(logs)} entries to #{remote}")

    case :rpc.call(remote, Stats.Mission, :register_log_entries, args) do
      {:badrpc, reason} ->
        Logger.error("RPC failed: #{inspect(reason)}")
        :error
      _ -> :ok
    end
  end

  # Schedule any queued logs to be sent in `@send_interval` milliseconds. Return
  # a reference to the timer task.
  @spec schedule_send() :: reference
  defp schedule_send() do
    Process.send_after(self(), :send_logs, @send_interval)
  end
end
