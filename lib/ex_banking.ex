defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """
  @type banking_error ::
          {:error, :wrong_arguments, :user_already_exists, :user_does_not_exist,
           :not_enough_money, :sender_does_not_exist, :receiver_does_not_exist,
           :too_many_requests_to_user, :too_many_requests_to_sender,
           :too_many_requests_to_receiver}

  alias ExBanking.User

  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) do
    case User.create_user(user) do
      {:ok, _user} -> :ok
      {:error, reason} -> reason
    end
  end
end
