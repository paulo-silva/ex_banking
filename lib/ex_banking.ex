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

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    case User.find_user(user) do
      {:ok, user} ->
        {:ok, Balance.get_balance(user, currency)}

      {:error, _reason} = error ->
        error
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    with {:from_user, {:ok, from_user}} <- {:from_user, User.find_user(from_user)},
         {:to_user, {:ok, to_user}} <- {:to_user, User.find_user(to_user)},
         {:withdraw, {:ok, from_user_balance}} <-
           {:withdraw, Balance.withdraw(from_user, currency, amount)},
         {:ok, to_user_balance} <- Balance.deposit(to_user, currency, amount) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:from_user, {:error, :user_does_not_exist}} ->
        {:error, :sender_does_not_exist}

      {:to_user, {:error, :user_does_not_exist}} ->
        {:error, :receiver_does_not_exist}

      {:withdraw, error} ->
        error
    end
  end
end
