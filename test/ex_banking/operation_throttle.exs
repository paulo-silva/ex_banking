defmodule ExBanking.OperationThrottleTest do
  use ExUnit.Case, async: true
  import Helpers

  doctest ExBanking.OperationThrottle

  setup do
    on_exit(&purge_ets_tables/0)
  end
end
