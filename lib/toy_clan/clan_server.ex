defmodule ToyClan.ClanServer do
  use GenServer

  alias ToyClan.PlayerNotifier

  alias ToyClan.Clan

  @type player :: %{id: Clan.player_id(), callback_mod: module()}


  @clans_supervisor ToyClan.ClansSup

  @spec child_spec() :: Supervisor.Spec.spec
  def child_spec() do
    {DynamicSupervisor, strategy: :one_for_one, name: @clans_supervisor}
  end

  @spec player_spec(Clan.player_id(), module()) :: player()
  def player_spec(player_id, callback_mod), do:
    %{id: player_id, callback_mod: callback_mod}

  @spec create_clan(Clan.clan_name(), Clan.clan_tags(), Clan.leader_id()) :: Supervisor.on_start_child
  def create_clan(clan_name, tags, leader_id) do
    opts = {clan_name, tags, leader_id}
    DynamicSupervisor.start_child(@clans_supervisor, {__MODULE__, opts})
  end

  @spec invate_player(Clan.clan_name(), Clan.player_id()) :: any()
  def invate_player(clan_name, player_id) do
    GenServer.call(service_name(clan_name), {:invate_player, player_id})
  end

  @spec invitation_answer(Clan.clan_name(), Clan.player_id(), Clan.invitation_answer()) :: any()
  def invitation_answer(clan_name, player_id, answer) do
    GenServer.call(service_name(clan_name), {:invitation_answer, player_id, answer})
  end

  @doc false
  def start_link({clan_name, _tags, _player_id} = opts) do
    GenServer.start_link(__MODULE__, opts, name: service_name(clan_name))
  end

  @doc false
  def init({clan_name, tags, player_id}) do
    {:ok,
      Clan.create(clan_name, tags, player_id)
      |> handle_result(%{clan: nil})
    }
  end

  @doc false
  def handle_call({:invate_player, player_id}, _from, state) do
    {:reply, :ok,
      state.clan
      |> Clan.invate_player(player_id)
      |> handle_result(state)
    }
  end

  def handle_call({:invitation_answer, player_id, answer}, _from, state) do
    {:reply, :ok,
      state.clan
      |> Clan.handle_invitation_answer(player_id,  answer)
      |> handle_result(state)
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
