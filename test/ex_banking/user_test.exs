defmodule ExBanking.UserTest do
  use ExUnit.Case, async: true
  import Helpers

  doctest ExBanking.User

  setup do
    on_exit(&purge_ets_tables/0)
  end
end
