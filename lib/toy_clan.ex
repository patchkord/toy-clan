defmodule ToyClan do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      [
        supervisor(Registry, [:unique, ToyClan.Registry]),
        ToyClan.ClanServer.child_spec()
      ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end

  def service_name(service_id), do:
    {:via, Registry, {ToyClan.Registry, service_id}}

end
