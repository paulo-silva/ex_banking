defmodule ExBanking.User do
  @moduledoc """
  Handle user creation
  """

  use GenServer

  @ets_table_name :users

  @spec find_user(user :: String.t()) :: {:ok, String.t()} | {:error, :user_does_not_exist}
  def find_user(user) when is_binary(user) and byte_size(user) > 0 do
    case :ets.lookup(@ets_table_name, user) do
      [{user}] -> {:ok, user}
      [] -> {:error, :user_does_not_exist}
    end
  end

  def find_user(_user), do: {:error, :wrong_arguments}

  @spec create_user(user :: String.t()) :: {:ok, String.t()} | {:error, Atom.t()}
  def create_user(user) when is_binary(user) and byte_size(user) > 0 do
    case find_user(user) do
      {:ok, _user} ->
        {:error, :user_already_exists}

      {:error, :user_does_not_exist} ->
        :ets.insert(@ets_table_name, {user})
        {:ok, user}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

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
