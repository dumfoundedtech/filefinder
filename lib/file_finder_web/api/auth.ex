defmodule FileFinderWeb.Api.Auth do
  @moduledoc """
  A module plug that verifies the bearer token in the request headers.
  The authorization header value may look like `Bearer xxxxxxx`.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> get_token()
    |> verify_token(conn)
    |> case do
      {:ok, shop_id} -> assign(conn, :shop_id, shop_id)
      _unauthorized -> assign(conn, :shop_id, nil)
    end
  end

  @doc """
  A function plug that ensures that `:shop_id` value is present.

  ## Examples

      # in a router pipeline
      pipe_through [:api, :authenticate_shop]

      # in a controller
      plug :authenticate_shop when action in [:index, :create]

  """
  def authenticate_shop(conn, _opts) do
    if Map.get(conn.assigns, :shop_id) do
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
  Verify a user token.

  ## Examples

      iex> FileFinderWeb.Api.Auth.verify_token("good-token", conn)
      {:ok, 1}

      iex> FileFinderWeb.Api.Auth.verify_token("bad-token", conn)
      {:error, :invalid}

      iex> FileFinderWeb.Api.Auth.verify_token("old-token", conn)
      {:error, :expired}

      iex> FileFinderWeb.Api.Auth.verify_token(nil, conn)
      {:error, :missing}

  """
  @spec verify_token(nil | binary, Plug.Conn.t()) ::
          {:error, :expired | :invalid | :missing} | {:ok, any}
  def verify_token(token, conn) do
    Phoenix.Token.verify(conn, "shop_id", token, max_age: 86400)
  end

  @spec get_token(Plug.Conn.t()) :: nil | binary
  def get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
