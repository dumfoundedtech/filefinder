defmodule FileFinderWeb.Plugs.Events do
  @moduledoc """
  A module plug that verifies webhook event signatures.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> get_signature()
    |> verify_signature(conn)
    |> case do
      {:ok} -> assign(conn, :event_topic, get_topic(conn))
      _unauthorized -> assign(conn, :event_topic, nil)
    end
  end

  @doc """
  A function plug that ensures that `:event_topic` value is present.

  ## Examples

      # in a router pipeline
      pipe_through [:events, :authenticate_event]

      # in a controller
      plug :authenticate_event when action in [:index, :create]

  """
  def authenticate_event(conn, _opts) do
    if Map.get(conn.assigns, :event_topic) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(FileFinderWeb.ErrorView)
      |> render(:"401")
      |> halt()
    end
  end

  @doc """
  Verify a webhook signature.

  ## Examples

      iex> FileFinderWeb.Plugs.Events.verify_signature("good-signature", conn)
      {:ok}

      iex> FileFinderWeb.Plugs.Events.verify_signature("bad-signature", conn)
      {:error, :invalid}

      iex> FileFinderWeb.Plugs.Events.verify_signature(nil, conn)
      {:error, :missing_signature}

  """
  @spec verify_signature(nil | binary, Plug.Conn.t()) ::
          {:error, :invalid | :missing_secret | :missing_signature} | {:ok}
  def verify_signature(signature, conn) do
    secret = System.get_env("SHOPIFY_SECRET")

    if secret do
      if signature do
        valid =
          :crypto.mac(:hmac, :sha256, secret, conn.private[:raw_body])
          |> Base.encode64()
          |> Plug.Crypto.secure_compare(signature)

        if valid do
          {:ok}
        else
          {:error, :invalid}
        end
      else
        {:error, :missing_signature}
      end
    else
      {:error, :missing_secret}
    end
  end

  @spec get_signature(Plug.Conn.t()) :: nil | binary
  def get_signature(conn) do
    conn |> get_req_header("x-shopify-hmac-sha256") |> List.first()
  end

  @spec get_topic(Plug.Conn.t()) :: nil | binary
  def get_topic(conn) do
    conn |> get_req_header("x-shopify-topic") |> List.first()
  end
end
