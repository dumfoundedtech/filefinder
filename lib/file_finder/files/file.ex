defmodule FileFinder.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

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

  @shopify_file_node """
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
  """

  @shopify_file_query """
    query ShopifyFile($id: ID!) {
      node(id: $id) {
        #{@shopify_file_node}
      }
    }
  """

  @shopify_stage_upload_query """
    mutation stageUpload($input: [StagedUploadInput!]!) {
      stagedUploadsCreate(input: $input) {
        stagedTargets {
          parameters {
            name
            value
          }
          resourceUrl
          url
        }
        userErrors {
          field
          message
        }
      }
    }
  """

  @shopify_file_create_query """
    mutation fileCreate($files: [FileCreateInput!]!) {
      fileCreate(files: $files) {
        files {
          #{@shopify_file_node}
        }
        userErrors {
          code
          field
          message
        }
      }
    }
  """

  @doc """
  Returns file ids from Shopify.

  ## Examples

      iex> request_shopify_ids(shop)
      {:ok, ["gid://shopify/MediaImage/123456789"]}
  """
  def request_shopify_ids(shop) do
    request_shopify_ids_help(nil, shop, [])
  end

  defp request_shopify_ids_help(cursor, shop, shopify_file_ids) do
    case send_shopify_request(@shopify_ids_query, %{cursor: cursor}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => %{"files" => files}}}} ->
        update =
          shopify_file_ids
          |> Enum.concat(Enum.map(files["nodes"], fn %{"id" => id} -> id end))

        if files["pageInfo"]["hasNextPage"] do
          files["pageInfo"]["endCursor"]
          |> request_shopify_ids_help(shop, update)
        else
          {:ok, update}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Creates a changeset for a new file based on the Shopify file.
  ## Examples

      iex> request_changeset("gid://shopify/MediaImage/123456789", shop)
      {:ok, #Ecto.Changeset{}}
  """
  def request_changeset(shopify_id, shop) do
    case request_shopify_file(shopify_id, shop) do
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

  defp request_shopify_file(shopify_id, shop) do
    case send_shopify_request(@shopify_file_query, %{id: shopify_id}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => %{"node" => node}}}} ->
        {:ok, node}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  """
  def create_shopify_file(file, alt, metadata, shop) do
    case stage_upload(metadata, shop) do
      {:ok, stage} ->
        case upload_to_stage(file, stage["url"], stage["parameters"]) do
          {:ok, _} ->
            shopify_create(stage["resourceUrl"], alt, metadata.mimetype, shop)

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # TODO: make private
  def stage_upload(metadata, shop) do
    vars = %{
      input: %{
        fileSize: metadata.filesize,
        filename: metadata.filename,
        httpMethod: "POST",
        mimeType: metadata.mimetype,
        resource: mimetype_to_content_type(metadata.mimetype)
      }
    }

    request = send_shopify_request(@shopify_stage_upload_query, vars, shop)

    case request do
      {:ok,
       %Neuron.Response{
         body: %{
           "data" => %{
             "stagedUploadsCreate" => %{"stagedTargets" => [staged | _]}
           }
         }
       }} ->
        {:ok, staged}

      {:ok,
       %Neuron.Response{
         body: %{
           "data" => %{"stagedUploadsCreate" => %{"userErrors" => errors}}
         }
       }} ->
        {:error, errors}

      {:ok, %Neuron.Response{body: %{"errors" => errors}}} ->
        {:error, errors}

      {:error, error} ->
        {:error, error}
    end
  end

  # TODO: make private
  def upload_to_stage(file, url, params) do
    # TODO: maybe use "form-data" method
    # https://www.shopify.in/partners/blog/upload-files-graphql-react
    # https://github.com/edgurgel/httpoison/issues/237
    # https://stackoverflow.com/questions/33557133/http-post-multipart-with-named-file
    # https://elixirforum.com/t/httpoison-post-multipart-with-more-form-than-the-file/4222/5
    # HTTPoison.post(
    #  url,
    #  {:multipart,
    #   [
    #     {:file, file, {"form-data", [{:name, ""}, {:filename, ""}]}, []}
    #   ]}
    # )
    HTTPoison.post(
      url,
      {:multipart,
       Enum.map(params, &{String.to_atom(&1["name"]), &1["value"]}) ++
         {:file, file, []}}
    )
  end

  # TODO: make private
  def shopify_create(url, alt, mimetype, shop) do
    vars = %{
      files: %{
        alt: alt,
        contentType: mimetype_to_content_type(mimetype),
        originalSource: url
      }
    }

    send_shopify_request(@shopify_file_create_query, vars, shop)
  end

  defp mimetype_to_content_type(mimetype) do
    case List.first(String.split(mimetype, "/")) do
      "image" ->
        "IMAGE"

      "video" ->
        "VIDEO"

      _ ->
        "FILE"
    end
  end

  defp send_shopify_request(query, vars, shop) do
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
