defmodule LogForwarder.Test.ForwarderMock do
  use GenServer

  alias :queue, as: Queue

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(_) do
    {:ok, %{
        buffer: Queue.new()
     }}
  end

  def enqueue_log_batch(server, batch) do
    GenServer.call(server, {:enqueue, batch})
  end

  def get_queue(server) do
    GenServer.call(server, :get_queue)
  end

  def handle_call({:enqueue, batch}, _from, state) do
    new_state = Map.update!(state, :buffer, &Queue.in(batch, &1))
    {:reply, :ok, new_state}
  end

  def handle_call(:get_queue, _from, state) do
    {:reply, state.buffer, state}
  end
end
