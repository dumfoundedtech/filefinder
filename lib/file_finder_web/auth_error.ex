defmodule FileFinderWeb.AuthError do
  defexception [:message, plug_status: 401]
end
