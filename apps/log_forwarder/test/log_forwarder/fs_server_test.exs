defmodule LogForwarder.FsServerTest do
  use ExUnit.Case
  doctest LogForwarder.FsServer

  alias :queue, as: Queue

  setup context do
    forwarder_name = String.to_atom(context[:dir] <> "_forwarder")
    _ = start_supervised!({LogForwarder.Test.ForwarderMock, name: forwarder_name})

    server_spec = %{
      id: context.test,
      start: {LogForwarder.FsServer, :start_link, [context[:dir], forwarder_name]},
   }

    _ = start_supervised!(server_spec)

    %{server: context.test, forwarder: forwarder_name}
  end

  @tag dir: "/test-init"
  test "init reads first log", %{forwarder: forwarder} do
    queue = LogForwarder.Test.ForwarderMock.get_queue(forwarder)
    assert Queue.len(queue) == 1

    {{:value, batch}, _} = Queue.out(queue)

    assert length(batch) == 1
  end

  @tag dir: "/test-init-many"
  test "init reads all logs", %{forwarder: forwarder} do
    queue = LogForwarder.Test.ForwarderMock.get_queue(forwarder)
    assert Queue.len(queue) == 2

    {{:value, batch}, queue} = Queue.out(queue)
    assert length(batch) == 1

    {{:value, batch}, _} = Queue.out(queue)
    assert length(batch) == 1
  end

  @tag dir: "/test-init-resume"
  test "init resumes from saved pointer", %{forwarder: forwarder} do
    queue = LogForwarder.Test.ForwarderMock.get_queue(forwarder)
    assert Queue.len(queue) == 1

    {{:value, batch}, _} = Queue.out(queue)
    assert length(batch) == 2
  end

  @tag dir: "/test-init-no-pointer"
  test "init with no pointer finds most recent logs", %{forwarder: forwarder} do
    queue = LogForwarder.Test.ForwarderMock.get_queue(forwarder)
    assert Queue.len(queue) == 2

    {{:value, batch}, queue} = Queue.out(queue)
    assert length(batch) == 1

    {{:value, batch}, _} = Queue.out(queue)
    assert length(batch) == 1
  end
end
