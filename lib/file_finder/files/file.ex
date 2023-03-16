defmodule FileFinder.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias FileFinder.Repo
  alias FileFinder.Shopify

  schema "files" do
    field :alt, :string
    field :mime_type, :string
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
    |> cast(
      attrs,
      [
        :shopify_id,
        :url,
        :type,
        :alt,
        :preview_url,
        :mime_type,
        :shopify_timestamp,
        :dir_id,
        :shop_id
      ],
      empty_values: [:alt]
    )
    |> validate_required([
      :shopify_id,
      :url,
      :type,
      :preview_url,
      :mime_type,
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
      fileStatus
      id
      mimeType
      originalFileSize
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
      fileStatus
      id
      image {
        url
      }
      mimeType
      originalSource {
        fileSize
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
      fileStatus
      id
      originalSource {
        fileSize
        mimeType
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

  @shopify_file_delete_query """
    mutation fileDelete($fileIds: [ID!]!) {
      fileDelete(fileIds: $fileIds) {
        deletedFileIds
        userErrors {
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
    case Shopify.send_request(@shopify_ids_query, %{cursor: cursor}, shop) do
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
        file = Repo.get_by(__MODULE__, shopify_id: shopify_id) || %__MODULE__{}
        {:ok, changeset(file, attrs_from_shopify_node(node, shop.id))}

      {:error, error} ->
        {:error, error}
    end
  end

  def request_shopify_file(shopify_id, shop) do
    case Shopify.send_request(@shopify_file_query, %{id: shopify_id}, shop) do
      {:ok, %Neuron.Response{body: %{"data" => %{"node" => node}}}} ->
        {:ok, node}

      {:error, error} ->
        {:error, error}
    end
  end

  def attrs_from_shopify_node(node, shop_id) do
    metadata =
      case node["__typename"] do
        "MediaImage" ->
          %{
            mime_type: node["mimeType"],
            type: :image,
            url: node["image"]["url"]
          }

        "Video" ->
          %{
            mime_type: node["originalSource"]["mimeType"],
            type: :video,
            url: node["originalSource"]["url"]
          }

        _ ->
          %{
            mime_type: node["mimeType"],
            type: :file,
            url: node["url"]
          }
      end

    %{
      "alt" => node["alt"],
      "mime_type" => metadata.mime_type,
      "preview_url" => node["preview"]["image"]["url"],
      "shop_id" => shop_id,
      "shopify_id" => node["id"],
      "shopify_timestamp" => node["createdAt"],
      "type" => metadata.type,
      "url" => metadata.url
    }
  end

  @doc """
  Creates a file on Shopify by first staging the file, then uploading the file
  to the stage, then creating the file from the staged url
  https://www.shopify.in/partners/blog/upload-files-graphql-react

  ## Examples

      iex> create_shopify_file("/path/to/file", "Alt", %{filesize: "1234", filename: "file.txt", mimetype: "text/plain"}, shop)
      {:ok, %Neuron.Response{}}
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

  defp stage_upload(metadata, shop) do
    vars = %{
      input: %{
        fileSize: metadata.filesize,
        filename: metadata.filename,
        httpMethod: "POST",
        mimeType: metadata.mimetype,
        resource: mimetype_to_content_type(metadata.mimetype)
      }
    }

    request = Shopify.send_request(@shopify_stage_upload_query, vars, shop)

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

  defp upload_to_stage(file, url, params) do
    HTTPoison.post(
      url,
      {:multipart,
       Enum.map(params, &{&1["name"], &1["value"]}) ++
         [{:file, file, []}]}
    )
  end

  defp shopify_create(url, alt, mimetype, shop) do
    vars = %{
      files: %{
        alt: alt,
        contentType: mimetype_to_content_type(mimetype),
        originalSource: url
      }
    }

    Shopify.send_request(@shopify_file_create_query, vars, shop)
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

  @doc """
  Deletes a file from Shopify.

  ## Examples

      iex> delete_shopify_file("gid://shopify/MediaImage/123456789", shop)
      {:ok, %Neuron.Response{}}
  """
  def delete_shopify_file(shopify_id, shop) do
    vars = %{
      fileIds: [shopify_id]
    }

    Shopify.send_request(@shopify_file_delete_query, vars, shop)
  end
end
