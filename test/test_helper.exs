Application.load(:mstr)

for app <- Application.spec(:mstr, :applications) do
  {:ok, _} = Application.ensure_all_started(app)
end

children = [
  Mstr.Repo,
  MstrWeb.Endpoint,
  {Phoenix.PubSub, name: Mstr.PubSub}
]

opts = [strategy: :one_for_one, name: Mstr.Supervisor]
Supervisor.start_link(children, opts)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Mstr.Repo, :manual)

defmodule SSpotify.TestHelpers do
  @on_load :load_atoms

  def load_atoms() do
    # modules need for `String.to_existing_atom` to work in tests.
    # details https://github.com/elixir-lang/elixir/issues/4832#issuecomment-227099444
    Enum.each([SSpotify.Track], &Code.ensure_loaded?/1)
    :ok
  end
end
