defmodule FileFinder.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  @shopify_ids_query """
    query ShopifyFileIds($cursor: String) {
      files(after: $cursor, first: 250, query: "status:READY") {
        nodes {
          ... on GenericFile {
            id
          }
          ... on MediaImage {
            id
          }
          ... on Video {
            id
          }
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
  """

  @shopify_file_query """
  query ShopifyFile($id: ID!) {
    node(id: $id) {
      __typename
      ... on GenericFile {
        alt
        createdAt
        preview {
          image {
            url
          }
        }
        url
      }
      ... on MediaImage {
        alt
        createdAt
        image {
          url
        }
        preview {
          image {
            url
          }
        }
      }
      ... on Video {
        alt
        createdAt
        originalSource {
          url
        }
        preview {
          image {
            url
          }
        }
      }
    }
  }
  """

  schema "files" do
    field :alt, :string
    field :preview_url, :string
    field :shopify_id, :string
    field :shopify_timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:file, :image, :video]
    field :url, :string
    belongs_to :dir, FileFinder.Files.Dir
    belongs_to :shop, FileFinder.Shops.Shop

    timestamps()
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [
      :shopify_id,
      :url,
      :type,
      :alt,
      :preview_url,
      :shopify_timestamp,
      :dir_id,
      :shop_id
    ])
    |> validate_required([
      :shopify_id,
      :url,
      :type,
      :preview_url,
      :shopify_timestamp,
      :shop_id
    ])
    |> unique_constraint(:shopify_id)
    |> unique_constraint(:url)
  end

  def new_file_changeset_from_shopify_id(shopify_id, shop) do
    case query_shopify_file(shopify_id, shop) do
      {:ok, node} ->
        {type, url} =
          case node["__typename"] do
            "MediaImage" ->
              {:image, node["image"]["url"]}

            "Video" ->
              {:video, node["originalSource"]["url"]}

            _ ->
              {:file, node["url"]}
          end

        {:ok,
         changeset(%FileFinder.Files.File{}, %{
           "alt" => node["alt"],
           "preview_url" => node["preview"]["image"]["url"],
           "shopify_id" => shopify_id,
           "shopify_timestamp" => node["createdAt"],
           "type" => type,
           "url" => url,
           "shop_id" => shop.id
         })}

      {:error, error} ->
        {:error, error}
    end
  end

  def query_shopify_ids(shop) do
    query_shopify_ids_help(nil, shop, [])
  end

  defp query_shopify_file(shopify_id, shop) do
    case query_shopify_api(@shopify_file_query, %{id: shopify_id}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => %{"node" => node}}}} ->
        {:ok, node}

      {:error, error} ->
        {:error, error}
    end
  end

  defp query_shopify_ids_help(cursor, shop, shopify_file_ids) do
    case query_shopify_api(@shopify_ids_query, %{cursor: cursor}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => %{"files" => files}}}} ->
        update =
          shopify_file_ids
          |> Enum.concat(Enum.map(files["nodes"], fn %{"id" => id} -> id end))

        if files["pageInfo"]["hasNextPage"] do
          files["pageInfo"]["endCursor"]
          |> query_shopify_ids_help(shop, update)
        else
          {:ok, update}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp query_shopify_api(query, vars, shop) do
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
