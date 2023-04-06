defmodule FileFinderWeb.AuthController do
  use FileFinderWeb, :controller

  plug Ueberauth

  alias FileFinder.Airtable
  alias FileFinder.Shops
  alias FileFinder.Shops.Shop

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    if has_valid_hmac?(conn, params) do
      attrs = map_response_to_shop(auth, params)
      shop = Shops.get_shop_by_name(attrs.name)

      if shop && shop.token == attrs.token do
        if Shop.get_current_plan(shop) do
          conn
          |> put_session(:shop_id, shop.id)
          |> redirect(to: "/")
        else
          # TODO: is this possible?
          subscribe_to_plan(conn, shop)
        end
      else
        if is_nil(shop) do
          case Shops.create_shop(attrs) do
            {:ok, created} ->
              {:ok, %Neuron.Response{body: %{"data" => data}}} = Shop.get_data(created)

              # side effects
              {:ok, _response} = Airtable.post_event("app/installed", data)
              {:ok, _response} = Shop.setup_events(created)

              # TODO: is this possible?
              if Shop.get_current_plan(created) do
                conn
                |> put_session(:shop_id, created.id)
                |> redirect(to: "/welcome")
              else
                subscribe_to_plan(conn, shop)
              end

            {:error, _} ->
              raise FileFinderWeb.Error, "Error creating shop"
          end
        else
          case Shops.update_shop(shop, %{token: attrs.token, active: true}) do
            {:ok, updated} ->
              {:ok, %Neuron.Response{body: %{"data" => data}}} = Shop.get_data(updated)

              # side effects
              {:ok, _response} = Airtable.post_event("app/reinstalled", data)
              {:ok, _response} = Shop.setup_events(updated)

              # TODO: is this possible?
              if Shop.get_current_plan(updated) do
                conn
                |> put_session(:shop_id, updated.id)
                |> redirect(to: "/welcome")
              else
                subscribe_to_plan(conn, updated)
              end

            {:error, _} ->
              raise FileFinderWeb.Error, "Error updating shop token"
          end
        end
      end
    else
      raise FileFinderWeb.Error, "Invalid params"
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}}, _params) do
    raise FileFinderWeb.Error, failure
  end

  defp has_valid_hmac?(conn, params) do
    if params["hmac"] do
      conf =
        Application.fetch_env!(
          :ueberauth,
          Ueberauth.Strategy.Shopify.OAuth
        )

      digest =
        conn.query_params
        |> Enum.reject(fn {k, _v} -> k == "hmac" end)
        |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
        |> Enum.join("&")

      hmac =
        :crypto.mac(:hmac, :sha256, conf[:client_secret], digest)
        |> Base.encode16(case: :lower)

      hmac == params["hmac"]
    else
      false
    end
  end

  defp map_response_to_shop(auth, params) do
    %{
      name: params["shop"],
      token: auth.credentials.token
    }
  end

  defp subscribe_to_plan(conn, shop) do
    case Shop.subscribe_to_plan(shop) do
      {:ok, %Neuron.Response{body: %{"data" => data}}} ->
        conn
        |> put_session(:shop_id, shop.id)
        |> redirect(external: data["appSubscriptionCreate"]["confirmationUrl"])

      {:error, _} ->
        raise FileFinderWeb.Error, "Error subscribing to plan"
    end
  end
end
