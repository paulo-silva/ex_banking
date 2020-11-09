defmodule ExBanking.BalanceTest do
  use ExUnit.Case, async: true
  import Helpers

  doctest ExBanking.Balance

  setup do
    on_exit(&purge_ets_tables/0)
  end
end
