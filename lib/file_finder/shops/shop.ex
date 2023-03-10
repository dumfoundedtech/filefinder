defmodule FileFinder.Shops.Shop do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shops" do
    field :name, :string
    field :token, :string
    has_many :dirs, FileFinder.Files.Dir
    has_many :files, FileFinder.Files.File

    timestamps()
  end

  @doc false
  def changeset(shop, attrs) do
    shop
    |> cast(attrs, [:name, :token])
    |> validate_required([:name, :token])
    |> unique_constraint(:name)
  end

  @webhook_subscription_create_query """
    mutation webhookSubscriptionCreate($topic: WebhookSubscriptionTopic!, $webhookSubscription: WebhookSubscriptionInput!) {
      webhookSubscriptionCreate(topic: $topic, webhookSubscription: $webhookSubscription) {
        webhookSubscription {
          id
          topic
          format
          endpoint {
            __typename
            ... on WebhookHttpEndpoint {
              callbackUrl
            }
          }
        }
      }
    }
  """

  def setup(shop) do
    vars = %{
      topic: "APP_UNINSTALLED",
      webhookSubscription: %{
        callbackUrl: "https://filefinderapp.com/events/app/uninstalled",
        format: "JSON"
      }
    }

    send_shopify_request(@webhook_subscription_create_query, vars, shop)
  end

  defp send_shopify_request(query, vars, shop) do
    config = Application.fetch_env!(:neuron, FileFinder.Files.File)

    Neuron.Config.set(url: "https://#{shop.name}" <> config[:endpoint])
    Neuron.Config.set(connection_opts: config[:connection_opts])

    Neuron.Config.set(
      headers: [
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": shop.token
      ]
    )

    Neuron.query(query, vars)
    |> FileFinder.pass_through_debug_log()
  end
end
