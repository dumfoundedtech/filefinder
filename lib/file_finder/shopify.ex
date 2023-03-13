defmodule FileFinder.Shopify do
  def send_request(query, vars, shop) do
    config = Application.fetch_env!(:neuron, FileFinder.Files.File)

    Neuron.Config.set(url: "https://#{shop.name}" <> config[:endpoint])
    Neuron.Config.set(connection_opts: config[:connection_opts])

    Neuron.Config.set(
      headers: [
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": shop.token
      ]
    )

    Neuron.query(query, vars)
    |> FileFinder.pass_through_debug_log()
  end
end
