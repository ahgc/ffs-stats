defmodule LogForwarder.Test.FileMock do
  @stamp "2018-03-25_18-51-45"
  @dummy_event "T:0 AType:15 VER:17"

  def exists?("/test-init/.ffs_stats_log_forwarder_head"), do: true
  def exists?("/test-init/missionReport(#{@stamp})[1].txt"), do:  false

  def exists?("/test-init-many/.ffs_stats_log_forwarder_head"), do: true
  def exists?("/test-init-many/missionReport(#{@stamp})[1].txt"), do: true
  def exists?("/test-init-many/missionReport(#{@stamp})[2].txt"), do: false

  def exists?("/test-init-resume/.ffs_stats_log_forwarder_head"), do: true
  def exists?("/test-init-resume/missionReport(#{@stamp})[2].txt"), do: false

  def exists?("/test-init-no-pointer/.ffs_stats_log_forwarder_head"), do: false
  def exists?("/test-init-no-pointer/missionReport(#{@stamp})[1].txt"), do: true
  def exists?("/test-init-no-pointer/missionReport(#{@stamp})[2].txt"),
    do: false


  def ls("/test-init-no-pointer") do
    {:ok, [
      "missionReport(2018-03-24_23_59_59)[0].txt",
      "foobar.txt",
      "missionReport(2018-03-25_18-51-44)[0].txt",
      "missionReport(#{@stamp})[1].txt",
      "missionReport(BigFaker)[infinity].txt",
      "missionReport(#{@stamp})[0].txt",
      "missionReport(2018-03-25_18-50-45)[0].txt",
    ]}
  end


  def stream!("/test-init/missionReport(#{@stamp})[0].txt") do
    [@dummy_event]
  end

  def stream!("/test-init-many/missionReport(#{@stamp})[0].txt") do
    [@dummy_event]
  end

  def stream!("/test-init-many/missionReport(#{@stamp})[1].txt") do
    [@dummy_event]
  end

  def stream!("/test-init-resume/missionReport(#{@stamp})[1].txt") do
    [
      "T:0 AType:15 VER:17",
      "T:1 AType:11 GID:775168 IDS:24576,44032,63488,82944 LID:24576",
      "T:1 AType:11 GID:776192 IDS:120832,142336,163840,185344 LID:120832",
    ]
  end

  def stream!("/test-init-no-pointer/missionReport(#{@stamp})[0].txt") do
    [@dummy_event]
  end

  def stream!("/test-init-no-pointer/missionReport(#{@stamp})[1].txt") do
    [@dummy_event]
  end


  def read!("/test-init/.ffs_stats_log_forwarder_head") do
    :erlang.term_to_binary({@stamp, 0, 0})
  end

  def read!("/test-init-many/.ffs_stats_log_forwarder_head") do
    :erlang.term_to_binary({@stamp, 0, 0})
  end

  def read!("/test-init-resume/.ffs_stats_log_forwarder_head") do
    :erlang.term_to_binary({@stamp, 1, 1})
  end


  def write("/test-init/.ffs_stats_log_forwarder_head", data) do
    assert_pointer(data, {@stamp, 0, 1})
  end

  def write("/test-init-many/.ffs_stats_log_forwarder_head", data) do
    assert_pointer(data, {@stamp, 1, 1})
  end

  def write("/test-init-resume/.ffs_stats_log_forwarder_head", data) do
    assert_pointer(data, {@stamp, 1, 3})
  end

  def write("/test-init-no-pointer/.ffs_stats_log_forwarder_head", data) do
    assert_pointer(data, {@stamp, 1, 1})
  end

  defp assert_pointer(actual, expected) do
    if actual == :erlang.term_to_binary(expected) do
      :ok
    else
      raise "head stamp mismatch. got #{inspect(:erlang.binary_to_term(actual))}"
    end
  end
end
