defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """
  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  alias ExBanking.{Balance, OperationThrottle, User}

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    result =
      case User.create_user(user) do
        {:ok, _user} -> :ok
        error -> error
      end

    OperationThrottle.dec_request(user)

    result
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    result =
      case validate_user(user) do
        {:ok, user} ->
          Balance.deposit(user, currency, amount)

        {:error, _reason} = error ->
          error
      end

    OperationThrottle.dec_request(user)

    result
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    result =
      case validate_user(user) do
        {:ok, user} ->
          Balance.withdraw(user, currency, amount)

        {:error, _reason} = error ->
          error
      end

    OperationThrottle.dec_request(user)

    result
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    result =
      case validate_user(user) do
        {:ok, user} ->
          Balance.get_balance(user, currency)

        {:error, _reason} = error ->
          error
      end

    OperationThrottle.dec_request(user)

    result
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    result =
      with {:from_user, {:ok, from_user}} <- {:from_user, validate_user(from_user)},
           {:to_user, {:ok, to_user}} <- {:to_user, validate_user(to_user)},
           {:withdraw, {:ok, from_user_balance}} <-
             {:withdraw, Balance.withdraw(from_user, currency, amount)},
           {:ok, to_user_balance} <- Balance.deposit(to_user, currency, amount) do
        {:ok, from_user_balance, to_user_balance}
      else
        {:from_user, {:error, :user_does_not_exist}} ->
          {:error, :sender_does_not_exist}

        {:to_user, {:error, :user_does_not_exist}} ->
          {:error, :receiver_does_not_exist}

        {:from_user, {:error, :too_many_requests_to_user}} ->
          {:error, :too_many_requests_to_sender}

        {:to_user, {:error, :too_many_requests_to_user}} ->
          {:error, :too_many_requests_to_receiver}

        {_, {:error, :wrong_arguments} = error} ->
          error

        {:withdraw, error} ->
          error
      end

    OperationThrottle.dec_request(from_user)
    OperationThrottle.dec_request(to_user)

    result
  end

  defp validate_user(user) do
    with {:ok, user} <- User.find_user(user),
         {:limit_reached?, false} <- {:limit_reached?, OperationThrottle.limit_reached?(user)} do
      OperationThrottle.inc_request(user)
      {:ok, user}
    else
      {:error, _reason} = error ->
        error

      {:limit_reached?, true} ->
        {:error, :too_many_requests_to_user}
    end
  end
end
