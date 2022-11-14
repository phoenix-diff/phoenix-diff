defmodule PhxDiff.Diffs.AppRepo.AppGenerator do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.AppGenerator.MixArchivesDirectories
  alias PhxDiff.Diffs.AppRepo.AppGenerator.MixTaskRunner
  alias PhxDiff.Diffs.Config

  @type dir :: String.t()

  @type generate_opt :: {:workspace_path, String.t()}

  @spec generate(Config.t(), AppSpecification.t()) ::
          {:ok, dir} | {:error, :unknown_version}
  def generate(%Config{} = config, %AppSpecification{} = app_specification) do
    %Config{app_generator_workspace_path: workspace_path} = config
    %AppSpecification{phoenix_version: version} = app_specification

    with {:ok, mix_archives_path} <-
           MixArchivesDirectories.fetch_path_for_phoenix_version(workspace_path, version) do
      generate_sample_app(workspace_path, mix_archives_path, app_specification)
    end
  end

  defp generate_sample_app(workspace_path, mix_archives_path, app_specification) do
    sample_app_path = generate_sample_app_path(workspace_path)

    with :ok <- run_phoenix_generator(sample_app_path, mix_archives_path, app_specification),
         :ok <- clean_up_generated_app!(sample_app_path) do
      {:ok, sample_app_path}
    end
  end

  defp run_phoenix_generator(sample_app_path, mix_archives_path, app_specification) do
    %AppSpecification{phx_new_arguments: arguments} = app_specification

    {_output, 0} =
      MixTaskRunner.run(
        [
          "phx.new",
          sample_app_path,
          "--module",
          "SampleApp",
          "--app",
          "sample_app"
        ] ++ arguments,
        env: [{"MIX_ARCHIVES", mix_archives_path}],
        prompt_responses: [:no_to_all]
      )

    :ok
  end

  defp clean_up_generated_app!(sample_app_path) do
    config_paths =
      sample_app_path
      |> Path.join("config/*.exs")
      |> Path.wildcard()

    endpoint_paths =
      sample_app_path
      |> Path.join("**/endpoint.ex")
      |> Path.wildcard()

    for path <- endpoint_paths ++ config_paths do
      update_file!(path, fn file ->
        updated =
          file
          |> replace_secret_key_base()
          |> replace_signing_salt()

        updated
      end)
    end

    :ok
  end

  defp replace_secret_key_base(file_contents) do
    String.replace(file_contents, ~r/(secret_key_base: )"[^"]*"/, ~S|\1"aaaaaaaa"|)
  end

  defp replace_signing_salt(file_contents) do
    String.replace(file_contents, ~r/(signing_salt: )"[^"]*"/, ~S|\1"aaaaaaaa"|)
  end

  defp update_file!(path, function) do
    path
    |> File.read!()
    |> function.()
    |> write_file!(path)
  end

  defp write_file!(contents, path) do
    File.write!(path, contents)
  end

  defp generate_sample_app_path(workspace_path) do
    Path.join([workspace_path, "generated_apps", random_string(16)])
  end

  defp random_string(length) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, length)
  end
end
