defmodule ToyClan.ClanServer do
  use GenServer

  alias ToyClan.PlayerNotifier

  alias ToyClan.Clan

  @type id :: any()
  @type player :: %{id: Clan.player_id(), callback_mod: module}
  @type callback_arg :: any()

  @clans_supervisor ToyClan.ClansSup

  @spec child_spec() :: Supervisor.Spec.spec
  def child_spec() do
    {DynamicSupervisor, strategy: :one_for_one, name: @clans_supervisor}
  end

  # @spec create_clan(id, [player]) :: Supervisor.on_start_child
  def create_clan(clan_id, player_id) do
    opts = {clan_id, player_id}
    DynamicSupervisor.start_child(@clans_supervisor, {__MODULE__, opts})
  end

  @doc false
  def start_link({clan_id, _player_id} = opts) do
    GenServer.start_link(__MODULE__, opts, name: service_name(clan_id))
  end

  @doc false
  def init({clan_id, player_id}) do
    {:ok,
      Clan.create(clan_id, [], player_id)
      |> handle_result(%{clan: nil})
    }
  end

  defp service_name(clan_id), do:
    ToyClan.service_name({__MODULE__, clan_id})

  defp handle_result({events, clan}, state), do:
    Enum.reduce(events, %{state | clan: clan}, &handle_event(&2, &1))

  defp handle_event(state, {:notify_player, player_id, event_payload}) do
    PlayerNotifier.publish(player_id, event_payload)
    state
  end
end
