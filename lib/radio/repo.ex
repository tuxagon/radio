defmodule Radio.Repo do
  use Ecto.Repo,
    otp_app: :radio,
    adapter: Ecto.Adapters.Postgres
end
