defmodule PhxDiff.Diffs.AppRepo.AppGenerator do
  @moduledoc false

  alias PhxDiff.Diffs.AppRepo.AppGenerator.MixArchivesDirectories
  alias PhxDiff.Diffs.AppRepo.AppGenerator.MixTaskRunner
  alias PhxDiff.Diffs.AppSpecification
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
    update_file!(Path.join(sample_app_path, "config/prod.secret.exs"), fn file ->
      String.replace(file, ~r/secret_key_base:.*/, "secret_key_base: \"aaaaaaaa\"")
    end)

    update_file!(Path.join(sample_app_path, "config/config.exs"), fn file ->
      file
      |> String.replace(~r/secret_key_base:.*/, "secret_key_base: \"aaaaaaaa\",")
      |> String.replace(~r/signing_salt:.*/, "signing_salt: \"aaaaaaaa\"]")
    end)

    update_file!(Path.join(sample_app_path, "lib/sample_app_web/endpoint.ex"), fn file ->
      String.replace(file, ~r/signing_salt:.*/, "signing_salt: \"aaaaaaaa\"")
    end)
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
