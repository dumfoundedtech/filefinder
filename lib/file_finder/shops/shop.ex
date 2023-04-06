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

  @setup_events_query """
    mutation setupEvents($topic: WebhookSubscriptionTopic!, $subscription: WebhookSubscriptionInput!) {
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

  def setup_events(shop) do
    vars = %{
      topic: "APP_UNINSTALLED",
      subscription: %{
        callbackUrl: System.get_env("EVENTS_ENDPOINT") <> "/events/app/uninstalled",
        format: "JSON"
      }
    }

    Shopify.send_request(@setup_events_query, vars, shop)
  end

  @get_current_plan_query """
    query currentPlan {
      currentAppInstallation {
        id
        activeSubscriptions {
          id
          name
        }
      }
    }
  """

  def get_current_plan(shop) do
    case Shopify.send_request(@get_current_plan_query, %{}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => data}}} ->
        sub = List.first(data["currentAppInstallation"]["activeSubscriptions"])

        if sub, do: sub["name"], else: nil

      _ ->
        nil
    end
  end

  @subscribe_to_plan_mutation """
    mutation subscribeToPlan($lineItems: [AppSubscriptionLineItemInput!]!, $name: String!, $returnUrl: URL!, $test: Boolean) {
      appSubscriptionCreate(lineItems: $lineItems, name: $name, returnUrl: $returnUrl, test: $test) {
        appSubscription {
          id
          name
          test
        }
        confirmationUrl
        userErrors {
          field
          message
        }
      }
    }
  """

  def subscribe_to_plan(shop) do
    vars = %{
      lineItems: [
        %{
          plan: %{
            appRecurringPricingDetails: %{
              price: %{amount: 43.0, currencyCode: "USD"},
              interval: "EVERY_30_DAYS"
            }
          }
        }
      ],
      name: "Basic Plan",
      returnUrl: FileFinderWeb.Endpoint.url() <> "/welcome",
      test: Application.get_env(:file_finder, :env) !== :prod
    }

    Shopify.send_request(@subscribe_to_plan_mutation, vars, shop)
  end
end
