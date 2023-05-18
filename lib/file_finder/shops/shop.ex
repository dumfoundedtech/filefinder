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

  @setup_event_mutation """
    mutation setupEvent($topic: WebhookSubscriptionTopic!, $subscription: WebhookSubscriptionInput!) {
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
    app_subscriptions_update_vars = %{
      topic: "APP_SUBSCRIPTIONS_UPDATE",
      subscription: %{
        callbackUrl: System.get_env("APP_ENDPOINT") <> "/events/app_subscriptions/update",
        format: "JSON"
      }
    }

    app_uninstalled_vars = %{
      topic: "APP_UNINSTALLED",
      subscription: %{
        callbackUrl: System.get_env("APP_ENDPOINT") <> "/events/app/uninstalled",
        format: "JSON"
      }
    }

    with {:ok, _response} <-
           Shopify.send_request(@setup_event_mutation, app_subscriptions_update_vars, shop) do
      Shopify.send_request(@setup_event_mutation, app_uninstalled_vars, shop)
    end
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
      returnUrl: System.get_env("APP_ENDPOINT") <> "/welcome",
      test:
        Application.get_env(:file_finder, :env) !== :prod ||
          System.get_env("PURCHASE_ENV") === "test",
      trialDays: 14
    }

    Shopify.send_request(@subscribe_to_plan_mutation, vars, shop)
  end
end
