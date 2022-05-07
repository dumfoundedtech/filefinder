defmodule FileFinder.Repo do
  use Ecto.Repo,
    otp_app: :file_finder,
    adapter: Ecto.Adapters.Postgres
end
