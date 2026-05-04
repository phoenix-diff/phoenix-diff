defmodule Mix.Tasks.PhxDiff.S3.Seed do
  @moduledoc false
  use Mix.Task

  use Boundary, deps: [PhxDiff]

  alias ExAws.S3, as: S3Client
  alias PhxDiff.Config

  @shortdoc "Seed S3 with sample apps"
  @requirements ["app.start"]

  def run(args) do
    {opts, _} = OptionParser.parse!(args, switches: [force: :boolean])

    repo_path = Config.app_repo_path()
    bucket = Config.app_repo_s3_bucket()
    prefix = Config.app_repo_s3_prefix()
    aws_config = build_aws_config()

    apps = find_apps(repo_path)
    app_count = length(apps)

    Mix.shell().info("Seeding #{app_count} apps to s3://#{bucket}/#{prefix}")

    {uploaded, skipped, failed} =
      apps
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0, 0}, fn {{version, variant}, index}, {uploaded, skipped, failed} ->
        app_label = "#{version}/#{variant}"

        Mix.shell().info("[#{index}/#{app_count}] Uploading #{app_label}")

        case upload_app(repo_path, bucket, prefix, aws_config, version, variant, opts[:force]) do
          :uploaded ->
            Mix.shell().info("[#{index}/#{app_count}] Uploaded #{app_label}")
            {uploaded + 1, skipped, failed}

          :skipped ->
            Mix.shell().info("[#{index}/#{app_count}] Skipped #{app_label}")
            {uploaded, skipped + 1, failed}

          :failed ->
            Mix.shell().error("[#{index}/#{app_count}] Failed #{app_label}")
            {uploaded, skipped, failed + 1}
        end
      end)

    Mix.shell().info("Uploaded: #{uploaded}; skipped: #{skipped}; failed: #{failed}")

    if failed > 0, do: exit({:shutdown, 1})
  end

  defp find_apps(repo_path) do
    repo_path
    |> File.ls!()
    |> Enum.flat_map(&find_variants(repo_path, &1))
  end

  defp find_variants(repo_path, version) do
    version_path = Path.join(repo_path, version)

    if File.dir?(version_path) do
      version_path |> File.ls!() |> Enum.map(&{version, &1})
    else
      []
    end
  end

  defp upload_app(repo_path, bucket, prefix, aws_config, version, variant, force) do
    app_path = Path.join([repo_path, version, variant])
    key = "#{prefix}/#{version}/#{variant}.tgz"

    archive = create_archive(app_path)

    opts = if force, do: [], else: [if_none_match: "*"]

    case S3Client.put_object(bucket, key, archive, opts) |> ExAws.request(aws_config) do
      {:ok, _} -> :uploaded
      {:error, {:http_error, 412, _}} -> :skipped
      {:error, _} -> :failed
    end
  end

  defp create_archive(dir_path) do
    tmp_file = Path.join(System.tmp_dir!(), "phx_diff_#{System.unique_integer([:positive])}.tgz")

    try do
      {_, 0} = System.cmd("tar", ["-czf", tmp_file, "-C", dir_path, "."])
      File.read!(tmp_file)
    after
      File.rm(tmp_file)
    end
  end

  defp build_aws_config do
    s3_base_url = Config.s3_base_url()
    uri = URI.parse(s3_base_url)

    [
      access_key_id: Config.s3_access_key_id(),
      secret_access_key: Config.s3_secret_access_key(),
      region: Config.app_repo_s3_region(),
      scheme: "#{uri.scheme}://",
      host: uri.host,
      port: uri.port,
      normalize_path: false,
      retries: [
        max_attempts: 1,
        max_attempts_client: 1
      ]
    ]
  end
end
