defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """
  @type banking_error ::
          {:error, :wrong_arguments, :user_already_exists, :user_does_not_exist,
           :not_enough_money, :sender_does_not_exist, :receiver_does_not_exist,
           :too_many_requests_to_user, :too_many_requests_to_sender,
           :too_many_requests_to_receiver}

  alias ExBanking.{Balance, User}

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    case User.create_user(user) do
      {:ok, _user} -> :ok
      error -> error
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    case User.find_user(user) do
      {:ok, user} ->
        Balance.deposit(user, currency, amount)

      {:error, _reason} = error ->
        error
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    case User.find_user(user) do
      {:ok, user} ->
        Balance.withdraw(user, currency, amount)

      {:error, _reason} = error ->
        error
    end
  end
end
