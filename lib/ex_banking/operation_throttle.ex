defmodule ExBanking.OperationThrottle do
  @moduledoc """
  Control how many pending operations a user can have.
  """

  use GenServer

  @ets_table_name :op_throttles
  @request_limit 10
  @throttle_ttl_msec 500

  def limit_reached?(user) do
    cur_requests = get_requests(user)

    if cur_requests >= @request_limit do
      :timer.apply_after(@throttle_ttl_msec, __MODULE__, :reset_limit, [user])

      true
    else
      false
    end
  end

  def reset_limit(user) do
    :ets.insert(@ets_table_name, {user, 0})
  end

  def get_requests(user) do
    case :ets.lookup(@ets_table_name, user) do
      [{^user, cur_req_number}] -> cur_req_number
      [] -> 0
    end
  end

  def inc_request(user) do
    cur_requests = get_requests(user)
    :ets.insert(@ets_table_name, {user, min(10, cur_requests + 1)})
  end

  def dec_request(user) do
    cur_requests = get_requests(user)
    :timer.sleep(1)
    :ets.insert(@ets_table_name, {user, max(0, cur_requests - 1)})
  end

  # Server callbacks

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(@ets_table_name, [:public, :named_table, read_concurrency: true])
    state = %{}

    {:ok, state}
  end

  @impl true
  def handle_call(:purge, _from, state) do
    :ets.delete_all_objects(@ets_table_name)

    {:reply, :ok, state}
  end
end
