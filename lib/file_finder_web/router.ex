defmodule FileFinderWeb.Router do
  use FileFinderWeb, :router

  pipeline :admin do
    plug :fetch_live_flash
    plug :put_root_layout, {FileFinderWeb.LayoutView, :root}
    plug :put_layout, {FileFinderWeb.LayoutView, :app}
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug FileFinderWeb.Api.Auth
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {FileFinderWeb.LayoutView, :main}
  end

  scope "/", FileFinderWeb do
    pipe_through :browser

    scope "/admin" do
      pipe_through :admin
      resources "/dirs", DirController
      resources "/files", FileController
      resources "/shops", ShopController
      get "/", PageController, :index
    end

    scope "/auth" do
      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end

    get "/", MainController, :index
  end

  scope "/api", FileFinderWeb.Api, as: :api do
    pipe_through [:api, :authenticate_shop]

    get "/shop/dirs/root/dirs", DirController, :root_shop_dirs
    get "/shop/dirs/:dir_id/dirs", DirController, :dir_shop_dirs
    patch "/dirs/:id", DirController, :update
    put "/dirs/:id", DirController, :update
    delete "/dirs/:id", DirController, :delete

    get "/shop/dirs/root/files", FileController, :root_shop_files
    get "/shop/dirs/:dir_id/files", FileController, :dir_shop_files
    patch "/files/:id", FileController, :update
    put "/files/:id", FileController, :update
    delete "/files/:id", FileController, :delete
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FileFinderWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
