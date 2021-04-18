defmodule AgentRadio.Repo do
  use Ecto.Repo,
    otp_app: :agent_radio,
    adapter: Ecto.Adapters.Postgres
end
