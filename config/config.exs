# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :file_finder,
  ecto_repos: [FileFinder.Repo]

# Configures the endpoint
config :file_finder, FileFinderWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: FileFinderWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: FileFinder.PubSub,
  live_view: [signing_salt: "kBrt0oaY"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :file_finder, FileFinder.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Ueberauth Shopify authentication
config :ueberauth, Ueberauth,
  providers: [
    shopify: {Ueberauth.Strategy.Shopify, [default_scope: "read_files,write_files"]}
  ]

# Neuron GraphQL client
config :neuron, FileFinder.Files.File, endpoint: "/admin/api/2023-01/graphql.json"

# Oban background jobs
config :file_finder, Oban,
  repo: FileFinder.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", FileFinder.Shops.BackgroundSyncScheduler}
     ]},
    Oban.Plugins.Pruner
  ],
  queues: [default: 10]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
