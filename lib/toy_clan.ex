defmodule ToyClan do
  use Application

  def start(_type, _args) do
    children =
      [
        Supervisor.child_spec({Registry, [{:keys, :unique}, {:name,ToyClan.Registry}]}, []),
        ToyClan.ClanServer.child_spec()
      ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end

  def service_name(service_id), do:
    {:via, Registry, {ToyClan.Registry, service_id}}

end
