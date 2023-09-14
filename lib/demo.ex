defmodule Demo do
  def run, do:
    Enum.map(1..5, &:"player_#{&1}")
    |> start_demo()

  defp start_demo(player_ids), do:
    Demo.AutoPlayer.Manager.start_link(player_ids)

end

defmodule Demo.AutoPlayer.Manager do
  use GenServer

  alias ToyClan.{ClanServer,PlayerNotifier}

  @behaviour PlayerNotifier

  @clan_name "Toy Clan"
  @clan_tags ["ELS", "WTF"]

  def start_link(player_ids), do:
    GenServer.start_link(__MODULE__, player_ids, name: __MODULE__)

  @doc false
  def init(player_ids) do
    players =
      Enum.map(player_ids, &ClanServer.player_spec(&1, __MODULE__))

    {:ok, %{players: players}, {:continue, player_ids}}
  end

  def handle_continue(player_ids, %{players: players} = state) do
    IO.puts("creating players... #{inspect(player_ids)}")
    Enum.each(players, &PlayerNotifier.start_link/1)

    leader = Enum.random(players)
    IO.puts("leader election...")

    IO.puts("creating a clan: #{@clan_name} with tags: #{inspect(@clan_tags)}\r\n")
    IO.puts("invating players... \r\n")
    ClanServer.create_clan(@clan_name, @clan_tags, leader.id)

    players
    |> Enum.reject(fn p -> leader == p end)
    |> Enum.each(fn player ->
      ClanServer.invate_player(@clan_name, player.id)
    end)

    {:noreply, state}
  end

  def message(player_id, data), do:
    IO.puts("#{player_id}: #{data} ")

  def invitation_request(player_id, clan_name, leader_id) do
    IO.puts("#{player_id}: got invitation to #{clan_name} from #{leader_id}")
    IO.puts("#{player_id}: thinking ...")
    ClanServer.invitation_answer(@clan_name, player_id, Demo.AutoPlayer.invitation_request())
  end
end

defmodule Demo.AutoPlayer do
  def invitation_request() do
    :timer.sleep(:rand.uniform(:timer.seconds(2)))

    if :rand.uniform(100) > 50 do
      :accept
    else
      :decline
    end
  end
end
