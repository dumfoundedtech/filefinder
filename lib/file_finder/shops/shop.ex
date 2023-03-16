defmodule FileFinder.Shops.Shop do
  use Ecto.Schema
  import Ecto.Changeset

  alias FileFinder.Shopify

  schema "shops" do
    field :name, :string
    field :token, :string
    field :active, :boolean, default: true
    has_many :dirs, FileFinder.Files.Dir
    has_many :files, FileFinder.Files.File

    timestamps()
  end

  @doc false
  def changeset(shop, attrs) do
    shop
    |> cast(attrs, [:name, :token, :active])
    |> validate_required([:name, :token])
    |> unique_constraint(:name)
  end

  @get_data_query """
    query getData {
      shop {
        billingAddress {
          company
          city
          province
          zip
          country
          phone
        }
        description
        email
        ianaTimezone
        id
        name
        plan {
          displayName
        }
      }
    }
  """

  def get_data(shop) do
    Shopify.send_request(@get_data_query, %{}, shop)
  end

  @setup_query """
    mutation setup($topic: WebhookSubscriptionTopic!, $subscription: WebhookSubscriptionInput!) {
      webhookSubscriptionCreate(topic: $topic, webhookSubscription: $subscription) {
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
      subscription: %{
        callbackUrl: System.get_env("EVENTS_ENDPOINT") <> "/events/app/uninstalled",
        format: "JSON"
      }
    }

    Shopify.send_request(@setup_query, vars, shop)
  end
end
