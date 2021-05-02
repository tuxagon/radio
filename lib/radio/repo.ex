defmodule Radio.Repo do
  use Ecto.Repo,
    otp_app: :radio,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    if config[:load_from_system_env] do
      db_url =
        System.get_env("DATABASE_URL") ||
          raise("expected the DATABASE_URL environment variable to be set")

      config = Keyword.put(config, :url, db_url)

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
