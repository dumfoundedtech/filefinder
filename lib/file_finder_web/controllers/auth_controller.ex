defmodule FileFinderWeb.AuthController do
  use FileFinderWeb, :controller

  plug Ueberauth

  alias FileFinder.Shops

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    if has_valid_hmac?(conn, params) do
      case Shops.create_or_update_shop(map_response_to_shop(auth, params)) do
        {:ok, shop} ->
          conn
          |> put_session(:shop_id, shop.id)
          |> redirect(to: "/")

        {:error, _} ->
          raise FileFinderWeb.Error, "Error creating shop"
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
