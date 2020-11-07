defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking.User

  describe "create_user/1" do
    test "should create a new user" do
      assert ExBanking.create_user("Paulo") == :ok
      assert User.find_user("Paulo") == {:ok, "Paulo"}
    end
  end
end
