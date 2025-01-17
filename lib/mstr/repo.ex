defmodule Mstr.Repo do
  use Ecto.Repo,
    otp_app: :mstr,
    adapter: Ecto.Adapters.Postgres
end
