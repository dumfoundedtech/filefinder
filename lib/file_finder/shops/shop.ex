defmodule FileFinder.Shops.Shop do
  use Ecto.Schema
  import Ecto.Changeset

  alias FileFinder.Shopify

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
        callbackUrl: System.get_env("EVENTS_ENDPOINT") <> "/events/app/uninstalled",
        format: "JSON"
      }
    }

    Shopify.send_request(@webhook_subscription_create_query, vars, shop)
  end
end
