defmodule StreamsUpload.Repo do
  use Ecto.Repo,
    otp_app: :streams_upload,
    adapter: Ecto.Adapters.Postgres
end
