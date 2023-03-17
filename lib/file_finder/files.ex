defmodule FileFinder.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  import File, only: [stat!: 1]
  alias FileFinder.Repo

  alias FileFinder.Files.Dir

  @doc """
  Returns the list of dirs.

  ## Examples

      iex> list_dirs()
      [%Dir{}, ...]

  """
  def list_dirs do
    Repo.all(Dir)
  end

  @doc """
  Gets a single dir.

  Raises `Ecto.NoResultsError` if the Dir does not exist.

  ## Examples

      iex> get_dir!(123)
      %Dir{}

      iex> get_dir!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dir!(id), do: Repo.get!(Dir, id)

  @doc """
  Creates a dir.

  ## Examples

      iex> create_dir(%{field: value})
      {:ok, %Dir{}}

      iex> create_dir(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dir(attrs \\ %{}) do
    %Dir{}
    |> Dir.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a dir.

  ## Examples

      iex> update_dir(dir, %{field: new_value})
      {:ok, %Dir{}}

      iex> update_dir(dir, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dir(%Dir{} = dir, attrs) do
    dir
    |> Dir.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a dir.

  ## Examples

      iex> delete_dir(dir)
      {:ok, %Dir{}}

      iex> delete_dir(dir)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dir(%Dir{} = dir) do
    Repo.delete(dir)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dir changes.

  ## Examples

      iex> change_dir(dir)
      %Ecto.Changeset{data: %Dir{}}

  """
  def change_dir(%Dir{} = dir, attrs \\ %{}) do
    Dir.changeset(dir, attrs)
  end

  def list_shop_dirs(shop_id, dir_id \\ nil) do
    if dir_id do
      from(d in Dir, where: d.shop_id == ^shop_id, where: d.dir_id == ^dir_id)
      |> Repo.all()
    else
      # from(d in Dir, where: d.shop_id == ^shop_id, where: is_nil(d.dir_id))
      # |> Repo.all()
      from(d in Dir, where: d.shop_id == ^shop_id) |> Repo.all()
    end
  end

  alias FileFinder.Files.File

  @doc """
  Returns the list of files.

  ## Examples

      iex> list_files()
      [%File{}, ...]

  """
  def list_files do
    Repo.all(File)
  end

  @doc """
  Gets a single file.

  Raises `Ecto.NoResultsError` if the File does not exist.

  ## Examples

      iex> get_file!(123)
      %File{}

      iex> get_file!(456)
      ** (Ecto.NoResultsError)

  """
  def get_file!(id), do: Repo.get!(File, id)

  @doc """
  Creates a file.

  ## Examples

      iex> create_file(%{field: value})
      {:ok, %File{}}

      iex> create_file(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file(attrs \\ %{}) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a file.

  ## Examples

      iex> update_file(file, %{field: new_value})
      {:ok, %File{}}

      iex> update_file(file, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file(%File{} = file, attrs) do
    file
    |> File.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a file.

  ## Examples

      iex> delete_file(file)
      {:ok, %File{}}

      iex> delete_file(file)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file(%File{} = file) do
    Repo.delete(file)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file changes.

  ## Examples

      iex> change_file(file)
      %Ecto.Changeset{data: %File{}}

  """
  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end

  def list_shop_files(shop_id, dir_id \\ nil) do
    if dir_id do
      from(f in File, where: f.shop_id == ^shop_id, where: f.dir_id == ^dir_id)
      |> Repo.all()
    else
      # from(f in File, where: f.shop_id == ^shop_id, where: is_nil(f.dir_id))
      # |> Repo.all()
      from(f in File, where: f.shop_id == ^shop_id) |> Repo.all()
    end
  end

  alias FileFinder.Shops

  def create_shop_file(shop_id, dir_id, file) do
    shop = Shops.get_shop!(shop_id)
    stat = stat!(file.path)

    metadata = %{
      filesize: "#{stat.size}",
      filename: file.filename,
      mimetype: file.content_type
    }

    case File.create_shopify_file(file.path, "", metadata, shop) do
      {:ok,
       %Neuron.Response{
         body: %{"data" => %{"fileCreate" => %{"files" => [node | _]}}}
       }} ->
        create_from_shopify(shop, node, dir_id)

      response ->
        response
    end
  end

  defp create_from_shopify(shop, node, dir_id) do
    case node["fileStatus"] do
      "READY" ->
        attrs = File.attrs_from_shopify_node(node, shop.id)

        if dir_id == "root" do
          create_file(attrs)
        else
          attrs
          |> Map.merge(%{"dir_id" => dir_id})
          |> create_file()
        end

      "FAILED" ->
        {:error, :failed}

      _ ->
        Process.sleep(1000)

        case File.request_shopify_file(node["id"], shop) do
          {:ok, node_} ->
            create_from_shopify(shop, node_, dir_id)

          response ->
            response
        end
    end
  end
end
