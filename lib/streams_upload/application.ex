defmodule StreamsUpload.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StreamsUploadWeb.Telemetry,
      # Start the Ecto repository
      # StreamsUpload.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: StreamsUpload.PubSub},
      # Start Finch
      {Finch, name: StreamsUpload.Finch},
      # Start the Endpoint (http/https)
      StreamsUploadWeb.Endpoint
      # Start a worker by calling: StreamsUpload.Worker.start_link(arg)
      # {StreamsUpload.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StreamsUpload.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StreamsUploadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
