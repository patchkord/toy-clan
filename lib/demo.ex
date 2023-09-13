defmodule Demo do
  def run do
    Enum.map(1..5, &:"player_#{&1}")
    |> start_scenario()
  end

  defp start_scenario(player_ids) do
    Demo.AutoPlayer.Controller.start_link(player_ids)
  end


  # defp start_round(round_id, player_ids) do
  #   Demo.AutoPlayer.Server.start_link(round_id, player_ids)

  #   Blackjack.RoundServer.start_playing(
  #     round_id,
  #     Enum.map(player_ids, &Demo.AutoPlayer.Server.player_spec(round_id, &1))
  #   )
  # end
end

defmodule Demo.AutoPlayer.Controller do
  use GenServer

  @behaviour ToyClan.PlayerNotifier
  alias Demo.AutoPlayer

  def start_link(player_ids), do:
    GenServer.start_link(__MODULE__, player_ids, name: __MODULE__)

  def player_spec(player_id), do:
    %{id: player_id, callback_mod: __MODULE__}

  @spec invate(Clan.player_id, Clan.clan_id) :: any()
  def invate(player_id, clan_id)  do
    IO.inspect("player: #{player_id} - invate: #{clan_id}")
  end

  @doc false
  def init(player_ids) do
    players =
      player_ids
      |> Enum.map(&{&1, AutoPlayer.new()}) |> Enum.into(%{})

    {:ok, %{players: players}}
  end

end

defmodule Demo.AutoPlayer do
  # use GenServer

  def start_link(player), do:
    ToyClan.PlayerNotifier.start_link(player)

  def new(), do: []

  def wellcome(player_id), do:
    IO.puts("Wellcome to ToyClan #{player_id}")

  # @spec decline(Clan.player_id) :: any()
  # def decline(player_id) do
  #   IO.inspect("player: #{player_id} - decline")
  # end
end
