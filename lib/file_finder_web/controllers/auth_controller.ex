defmodule FileFinderWeb.AuthController do
  use FileFinderWeb, :controller

  plug Ueberauth

  alias FileFinder.Shops

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    if has_valid_hmac?(conn, params) do
      attrs = map_response_to_shop(auth, params)
      shop = Shops.get_shop_by_name(attrs.name)

      if shop && shop.token == attrs.token do
        conn
        |> put_session(:shop_id, shop.id)
        |> redirect(to: "/")
      else
        if is_nil(shop) do
          # fresh install
          case Shops.create_shop(attrs) do
            {:ok, created} ->
              conn
              |> put_session(:shop_id, created.id)
              |> redirect(to: "/")

            {:error, _} ->
              raise FileFinderWeb.Error, "Error creating shop"
          end
        else
          # is this a reinstall?
          case Shops.update_shop(shop, %{token: attrs.token}) do
            {:ok, updated} ->
              conn
              |> put_session(:shop_id, updated.id)
              |> redirect(to: "/")

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
end
