defmodule LogForwarder.Test.FileMock do
  @stamp "2018-03-25_18-51-45"

  # test-init
  def exists?("/test-init/.ffs_stats_log_forwarder_head") do
    true
  end

  def exists?("/test-init/missionReport(#{@stamp})[1].txt") do
    false
  end

  def read!("/test-init/.ffs_stats_log_forwarder_head") do
    :erlang.term_to_binary({@stamp, 0, 0})
  end

  def stream!("/test-init/missionReport(#{@stamp})[0].txt") do
    ["T:0 AType:15 VER:17"]
  end

  def write("/test-init/.ffs_stats_log_forwarder_head", data) do
    if data == :erlang.term_to_binary({@stamp, 0, 1}) do
      :ok
    else
      raise "head stamp mismatch. got #{:erlang.binary_to_term(data)}"
    end
  end

  # test-init2
  def exists?("/test-init2/.ffs_stats_log_forwarder_head") do
    true
  end

  def exists?("/test-init2/missionReport(#{@stamp})[1].txt") do
    true
  end

  def exists?("/test-init2/missionReport(#{@stamp})[2].txt") do
    false
  end

  def read!("/test-init2/.ffs_stats_log_forwarder_head") do
    :erlang.term_to_binary({@stamp, 0, 0})
  end

  def write("/test-init2/.ffs_stats_log_forwarder_head", data) do
    if data == :erlang.term_to_binary({@stamp, 1, 1}) do
      :ok
    else
      raise "head stamp mismatch. got #{:erlang.binary_to_term(data)}"
    end
  end

  def stream!("/test-init2/missionReport(#{@stamp})[0].txt") do
    ["T:0 AType:15 VER:17"]
  end

  def stream!("/test-init2/missionReport(#{@stamp})[1].txt") do
    ["T:0 AType:15 VER:17"]
  end
end
