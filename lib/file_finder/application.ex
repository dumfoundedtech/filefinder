defmodule FileFinder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      FileFinder.Repo,
      # Start the Telemetry supervisor
      FileFinderWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: FileFinder.PubSub},
      # Start the Endpoint (http/https)
      FileFinderWeb.Endpoint,
      # Start Oban background jobs
      {Oban, Application.fetch_env!(:file_finder, Oban)}
      # Start a worker by calling: FileFinder.Worker.start_link(arg)
      # {FileFinder.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FileFinder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FileFinderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
