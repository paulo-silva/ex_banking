defmodule ExBanking.Balance do
  @moduledoc """
  Handle deposit/withdraws to a user balance.
  """

  use GenServer

  @ets_table_name :balances

  @doc """
  Make a deposit to a user account.

  Returns {:ok, balance}

  ## Examples

      iex> ExBanking.Balance.deposit("Paulo", "USD", 50)
      {:ok, 50}

      iex> ExBanking.Balance.deposit("Paulo", "USD", -50)
      {:error, :wrong_arguments}

      iex> ExBanking.Balance.deposit(1, "USD", 50)
      {:error, :wrong_arguments}
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | {:error, Atom.t()}
  def deposit(user, currency, amount) when is_binary(user) and is_binary(currency) do
    update_balance(user, currency, amount, "deposit")
  end

  def deposit(_user, _balance, _amount), do: {:error, :wrong_arguments}

  @doc """
  Make a withdraw to a user account.

  Returns {:ok, balance}

  ## Examples

      iex> ExBanking.Balance.withdraw("Paulo", "USD", 50)
      {:error, :not_enough_money}

      iex> ExBanking.Balance.deposit("Paulo", "USD", 50)
      ...> ExBanking.Balance.withdraw("Paulo", "USD", 50)
      {:ok, 0}

      iex> ExBanking.Balance.withdraw(1, "USD", 50)
      {:error, :wrong_arguments}
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | {:error, Atom.t()}
  def withdraw(user, currency, amount) when is_binary(user) and is_binary(currency) do
    update_balance(user, currency, amount, "withdraw")
  end

  def withdraw(_user, _balance, _amount), do: {:error, :wrong_arguments}

  @doc """
  Get current balance of the provided user and currency.

  Returns {:ok, balance}

  ## Examples

      iex> ExBanking.Balance.get_balance("Paulo", "USD")
      {:ok, 0}

      iex> ExBanking.Balance.deposit("Paulo", "USD", 50)
      ...> ExBanking.Balance.get_balance("Paulo", "USD")
      {:ok, 50}

      iex> ExBanking.Balance.get_balance(1, "USD")
      {:error, :wrong_arguments}
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, Integer.t()} | {:error, :wrong_arguments}
  def get_balance(user, currency) when not is_binary(user) or not is_binary(currency),
    do: {:error, :wrong_arguments}

  def get_balance(user, currency) do
    key = {user, currency}

    case :ets.lookup(@ets_table_name, key) do
      [{^key, cur_balance}] -> {:ok, cur_balance}
      [] -> {:ok, 0}
    end
  end

  defp update_balance(user, currency, amount, "deposit") do
    case format_amount(amount) do
      {:ok, amount} ->
        {:ok, cur_balance} = get_balance(user, currency)
        key = {user, currency}

        new_balance = cur_balance + amount
        :ets.insert(@ets_table_name, {key, new_balance})

        {:ok, new_balance}

      {:error, :wrong_arguments} = error ->
        error
    end
  end

  defp update_balance(user, currency, amount, "withdraw") do
    case format_amount(amount) do
      {:ok, amount} ->
        {:ok, cur_balance} = get_balance(user, currency)
        key = {user, currency}

        if cur_balance >= amount do
          new_balance = cur_balance - amount
          :ets.insert(@ets_table_name, {key, new_balance})

          {:ok, new_balance}
        else
          {:error, :not_enough_money}
        end

      {:error, :wrong_arguments} = error ->
        error
    end
  end

  defp format_amount(amount) when amount < 0, do: {:error, :wrong_arguments}
  defp format_amount(amount) when is_float(amount), do: {:ok, trunc(amount * 100) / 100}
  defp format_amount(amount), do: {:ok, amount}

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
