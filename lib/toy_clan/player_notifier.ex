defmodule ToyClan.PlayerNotifier do
  use GenServer

  alias ToyClan
  alias ToyClan.Clan

  @callback message(Clan.player_id(), any()) :: any()
  @callback invitation_request(Clan.player_id(), Clan.clan_name(), Clan.leader_id()) :: any()

  @spec publish(Clan.player_id, Clan.player_event) :: :ok
  def publish(player_id, player_event), do:
    GenServer.cast(service_name(player_id), {:notify, player_event})

  @doc false
  def start_link(player), do:
    GenServer.start_link(__MODULE__, player, name: service_name(player.id))

  @doc false
  def init(player), do:
    {:ok, %{player: player} }

  @doc false
  def handle_cast({:notify, player_event}, state) do
    {fun, args} = decode_event(player_event)
    all_args = [state.player.id | args]
    apply(state.player.callback_mod, fun, all_args)
    {:noreply, state}
  end

  def service_name(player_id), do:
    ToyClan.service_name({__MODULE__, player_id})

  defp decode_event({:message, data}), do:
    {:message, [data]}
  defp decode_event({:invitation_request, clan_name, leader_id}), do:
    {:invitation_request, [clan_name, leader_id]}

 end
