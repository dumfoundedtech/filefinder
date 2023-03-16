defmodule FileFinder.Airtable do
  def post_event(topic, data) do
    url =
      "https://api.airtable.com/v0/" <>
        System.get_env("AIRTABLE_BASE") <>
        "/" <>
        System.get_env("AIRTABLE_TABLE")

    body = %{records: [%{fields: %{Topic: topic, Body: Jason.encode!(data)}}]}

    HTTPoison.post(url, Jason.encode!(body), [
      {"Authorization", "Bearer " <> System.get_env("AIRTABLE_TOKEN")},
      {"Content-Type", "application/json"}
    ])
  end
end
