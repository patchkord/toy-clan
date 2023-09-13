defmodule ToyClan.Clan do
  alias ToyClan.Clan
  use TypedStruct

  alias __MODULE__

  @type player_id :: any
  @type clan_id :: any

  @type player_event ::
    {:accept, clan_id} | :decline

  @type event :: {:notify_player, player_id, player_event}

  typedstruct opaque: true  do
    field :name, String.t(), enforce: true
    field :tags, [Atom.t()], default: []

    field :leader, player_id
    field :players, [player_id]

    field :events, [event]
  end

  # @spec create(Clan.name.t(), Clan.tags(), Clan.leader()) :: Clan.t()
  def create(name, tags, leader) do
    struct(Clan, name: name)
    |> struct(tags: tags)
    |> struct(leader: leader)
    |> struct(players: [leader])
    |> struct(events: [])
    |> notify_player(leader, :wellcome)
    |> events_and_state()
  end

  @spec invate_player(t(), player_id()) :: {[event()], t()}
  def invate_player(%Clan{leader: leader} = clan, player_id) do
    clan
    |> notify_player(player_id, {:invitation_request, clan.name})
    |> notify_player(leader, :invitation_request_sent)
    |> events_and_state()
  end

  defp notify_player(clan, player_id, data), do:
    %Clan{clan | events: [{:notify_player, player_id, data} | clan.events]}

  defp events_and_state(clan), do:
    take_events(clan)

  defp take_events(clan), do:
    {Enum.reverse(clan.events), %Clan{clan | events: []}}
end
