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

  def invitation_request(player_id, clan_name, leader_id), do:
    GenServer.call(__MODULE__, {:invitation_request, player_id, clan_name, leader_id})

  def invitation_answer(leader_id, invitation_answer, player_id), do:
    GenServer.call(__MODULE__, {:invitation_answer, leader_id, invitation_answer, player_id})

  def clan_created(player_id, clan_name), do:
    GenServer.call(__MODULE__, {:invate_player, clan_name, player_id})

  def players_list(player_id, data), do:
    GenServer.call(__MODULE__, {:players_list, player_id, data})
    # IO.puts("#{player_id}: players_list - #{data |> inspect()} ")
  # end

  def message(player_id, data), do:
    IO.puts("#{player_id}: #{data} ")

  @doc false
  def init(player_ids) do
    players =
      Enum.map(player_ids, &ClanServer.player_spec(&1, __MODULE__))
      |> Enum.shuffle()

    {:ok, players, {:continue, player_ids}}
  end

  def handle_continue(player_ids, [leader|followers] = players) do
    IO.puts("creating players... #{inspect(player_ids)}")
    Enum.each(players, &PlayerNotifier.start_link/1)

    IO.puts("leader elected: #{leader.id}")
    IO.puts("creating a clan: #{@clan_name} with tags: #{inspect(@clan_tags)}\r\n")
    ClanServer.create_clan(@clan_name, @clan_tags, leader.id)

    {:noreply, followers}
  end

  def handle_call({:invate_player, clan_name, player_id}, from, [player|followers]) do
    GenServer.reply(from, :ok)
    IO.puts("#{player_id}: invating players to #{clan_name} ... ")

    ClanServer.invate_player(@clan_name, player.id)
    {:noreply, followers}
  end

  def handle_call({:invitation_request, player_id, clan_name, leader_id}, from, state) do
    GenServer.reply(from, :ok)

    IO.puts("#{player_id}: got invitation to #{clan_name} from #{leader_id}")
    IO.puts("#{player_id}: thinking ...")
    ClanServer.invitation_answer(@clan_name, player_id, Demo.AutoPlayer.invitation_request())

    {:noreply, state}
  end

  @doc false
  def handle_call({:invitation_answer, leader_id, answer, player_id}, from, players) do
    GenServer.reply(from, :ok)
    case answer do
        :accept ->
          IO.puts("#{leader_id}: #{player_id} has accepted invitation to #{@clan_name}")
        :decline ->
          IO.puts("#{leader_id}: #{player_id} has declined invitation to #{@clan_name}")
    end

    state =
      case players do
        [] ->
          ClanServer.players_list(@clan_name, leader_id)
          [];
        [player|players] ->
          ClanServer.invate_player(@clan_name, player.id)
          players
      end

    {:noreply, state}
  end

  def handle_call({:players_list, player_id, data}, from, state) do
    GenServer.reply(from, :ok)
    IO.puts("#{player_id}: players_list - #{data |> inspect()} ")
    IO.puts("#{player_id}: going to kick someone of ... ")

    case data do
      [] ->
        IO.puts("#{player_id}: there is not player to kick ")

      players_list ->
        ClanServer.dismiss_player(@clan_name, Enum.random(players_list), player_id)
    end

    {:noreply, state}
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
