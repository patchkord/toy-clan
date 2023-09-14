defmodule ToyClan.Clan do
  alias ToyClan.Clan
  use TypedStruct

  alias __MODULE__

  @type player_id :: any
  @type leader_id :: player_id()
  @type clan_name :: String.t()
  @type clan_tags :: [Atom.t()]

  @type player_event ::
    {:message, String.t()} |
    {:invitation_request, clan_name(), leader_id()}

  @type event :: {:notify_player, player_id, player_event}

  @type invitation_answer ::  :accept | :decline

  typedstruct opaque: true  do
    field :name, clan_name(), enforce: true
    field :tags, clan_tags(), default: []


    field :leader_id, leader_id()
    field :players_ids, [player_id()]

    field :events, [event]
  end

  @spec create(clan_name(), clan_tags(), leader_id()) :: {[event], t}
  def create(clan_name, tags, leader_id) do
    struct(Clan, name: clan_name)
    |> struct(tags: tags)
    |> struct(leader_id: leader_id)
    |> struct(players_ids: [leader_id])
    |> struct(events: [])
    |> notify_player(leader_id, {:message, "greeting from #{clan_name} "} )
    |> events_and_state()
   end

  def invate_player(%Clan{leader_id: _leader_id} = clan, player_id) do
     clan
    |> notify_player(player_id, {:invitation_request, clan.name, clan.leader_id})
    |> events_and_state()
  end

  def handle_invitation_answer(%Clan{leader_id: leader_id} = clan, player_id, :accept) do
    %Clan{clan | players_ids: [player_id | clan.players_ids]}
    |> notify_player(leader_id, {:message, "#{player_id} has accepted invitation to #{clan.name}"} )
    |> events_and_state()
  end

  def handle_invitation_answer(%Clan{leader_id: leader_id} = clan, player_id, :decline) do
    clan
    |> notify_player(leader_id, {:message, "#{player_id} has declined invitation to #{clan.name}"} )
    |> events_and_state()
  end

  defp notify_player(clan, player_id, data), do:
    %Clan{clan | events: [{:notify_player, player_id, data} | clan.events]}

  defp events_and_state(clan), do:
    take_events(clan)

  defp take_events(clan), do:
    {Enum.reverse(clan.events), %Clan{clan | events: []}}
end
