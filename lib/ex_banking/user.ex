defmodule ExBanking.User do
  @moduledoc """
  Handle user creation
  """

  use GenServer

  @ets_table_name :users

  @doc """
  Search for a given user in users ets table.

  Returns {:ok, user}

  ## Examples

      iex> ExBanking.User.create_user("Paulo")
      ...> ExBanking.User.find_user("Paulo")
      {:ok, "Paulo"}

      iex> ExBanking.User.find_user("Adam")
      {:error, :user_does_not_exist}

      iex> ExBanking.User.find_user(1)
      {:error, :wrong_arguments}
  """
  @spec find_user(user :: String.t()) :: {:ok, String.t()} | {:error, :user_does_not_exist}
  def find_user(user) when not is_binary(user), do: {:error, :wrong_arguments}

  def find_user(user) do
    case :ets.lookup(@ets_table_name, user) do
      [{user}] -> {:ok, user}
      [] -> {:error, :user_does_not_exist}
    end
  end

  @doc """
  Create a user in users ets table, unless the user already exist.

  Returns {:ok, user}

  ## Examples

      iex> ExBanking.User.create_user("Paulo")
      {:ok, "Paulo"}

      iex> ExBanking.User.create_user(1)
      {:error, :wrong_arguments}

      iex> ExBanking.User.create_user("Barbara")
      ...> ExBanking.User.create_user("Barbara")
      {:error, :user_already_exists}
  """
  @spec create_user(user :: String.t()) :: {:ok, String.t()} | {:error, Atom.t()}
  def create_user(user) when not is_binary(user), do: {:error, :wrong_arguments}

  def create_user(user) do
    case find_user(user) do
      {:ok, _user} ->
        {:error, :user_already_exists}

      {:error, :user_does_not_exist} ->
        :ets.insert(@ets_table_name, {user})
        {:ok, user}
    end
  end

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
