defmodule ExBanking.Balance do
  @moduledoc """
  Handle deposit creation
  """

  use GenServer

  @ets_table_name :balances

  # Server callbacks

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | {:error, Atom.t()}
  def deposit(user, currency, amount) when is_binary(user) and is_binary(currency) do
    update_balance(user, currency, amount, "deposit")
  end

  def deposit(_user, _balance, _amount), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | {:error, Atom.t()}
  def withdraw(user, currency, amount) when is_binary(user) and is_binary(currency) do
    update_balance(user, currency, amount, "withdraw")
  end

  def withdraw(_user, _balance, _amount), do: {:error, :wrong_arguments}

  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    key = {user, currency}

    case :ets.lookup(@ets_table_name, key) do
      [{^key, cur_balance}] -> {:ok, cur_balance}
      [] -> {:ok, 0}
    end
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

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
