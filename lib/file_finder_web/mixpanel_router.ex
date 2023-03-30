defmodule FileFinderWeb.MixpanelRouter do
  use FileFinderWeb, :router

  pipeline :proxy do
    plug :accepts, ["js", "json"]
  end

  scope "/", FileFinderWeb do
    pipe_through :proxy

    get "/lib.js", MixpanelController, :lib_js
    get "/lib.min.js", MixpanelController, :lib_min_js
    get "/*path", MixpanelController, :api_request
  end
end
