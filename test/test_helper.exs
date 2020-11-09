alias ExBanking.{Balance, OperationThrottle, User}

ExUnit.start()

defmodule Helpers do
  def purge_ets_tables do
    GenServer.call(User, :purge)
    GenServer.call(Balance, :purge)
    GenServer.call(OperationThrottle, :purge)
  end
end
