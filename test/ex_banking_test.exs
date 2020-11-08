defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking.{Balance, User}

  setup do
    on_exit(fn ->
      GenServer.call(User, :purge)
      GenServer.call(Balance, :purge)
    end)
  end

  describe "create_user/1" do
    test "create a new user" do
      assert ExBanking.create_user("Paulo") == :ok
      assert User.find_user("Paulo") == {:ok, "Paulo"}
    end

    test "fail if user already exist" do
      :ok = ExBanking.create_user("Paulo")

      assert ExBanking.create_user("Paulo") == {:error, :user_already_exists}
    end
  end

  describe "deposit/3" do
    test "make a deposit" do
      :ok = ExBanking.create_user("Paulo")

      assert ExBanking.deposit("Paulo", 150, "USD") == {:ok, 150}
    end

    test "should format amount to be 2 decimal precision" do
      :ok = ExBanking.create_user("Paulo")

      assert ExBanking.deposit("Paulo", 1234.86552, "USD") == {:ok, 1234.86}
    end

    test "fail if user does not exist" do
      assert ExBanking.deposit("Paulo", 150, "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "withdraw/3" do
    test "make a withdraw" do
      :ok = ExBanking.create_user("Paulo")
      ExBanking.deposit("Paulo", 150, "USD")

      assert ExBanking.withdraw("Paulo", 50, "USD") == {:ok, 100}
    end

    test "should format amount to be 2 decimal precision" do
      :ok = ExBanking.create_user("Paulo")
      ExBanking.deposit("Paulo", 150, "USD")

      assert ExBanking.withdraw("Paulo", 123.33333, "USD") == {:ok, 26.67}
    end

    test "fail if balance is lower than provided amount" do
      assert ExBanking.withdraw("Paulo", 50, "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "get_balance/2" do
    test "returns current balance of a user" do
      :ok = ExBanking.create_user("Paulo")

      assert ExBanking.get_balance("Paulo", "USD") == {:ok, 0}

      ExBanking.deposit("Paulo", 150, "USD")

      assert ExBanking.get_balance("Paulo", "USD") == {:ok, 150}
    end

    test "fail if user does not exist" do
      assert ExBanking.get_balance("Paulo", "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "send/4" do
    test "transfer money to one user to another" do
      :ok = ExBanking.create_user("Paulo")
      :ok = ExBanking.create_user("Barbara")
      ExBanking.deposit("Paulo", 100, "USD")

      assert ExBanking.send("Paulo", "Barbara", 50, "USD") == {:ok, 50, 50}
    end

    test "fail if sender does not exist" do
      :ok = ExBanking.create_user("Barbara")

      assert ExBanking.send("Paulo", "Barbara", 50, "USD") == {:error, :sender_does_not_exist}
    end

    test "fail if receiver does not exist" do
      :ok = ExBanking.create_user("Paulo")

      assert ExBanking.send("Paulo", "Barbara", 50, "USD") == {:error, :receiver_does_not_exist}
    end

    test "fail if sender does not have enough money" do
      :ok = ExBanking.create_user("Paulo")
      :ok = ExBanking.create_user("Barbara")

      ExBanking.deposit("Paulo", 40, "USD")

      assert ExBanking.send("Paulo", "Barbara", 50, "USD") == {:error, :not_enough_money}
      assert ExBanking.get_balance("Paulo", "USD") == {:ok, 40}
      assert ExBanking.get_balance("Barbara", "USD") == {:ok, 0}
    end
  end
end
