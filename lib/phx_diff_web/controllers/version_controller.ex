defmodule PhxDiffWeb.VersionController do
  use PhxDiffWeb, :controller

  def index(conn, _params) do
    body = build_response_body()

    conn
    |> put_resp_content_type("text/plain", nil)
    |> send_resp(200, body)
  end

  defp build_response_body do
    header = """
    # Each line lists the app specifications available for that version.
    # Use the app spec directly in the /browse endpoint (URL-encode spaces as %20).
    # Example: /browse/1.8.5%20--no-ecto/raw/mix.exs

    """

    version_lines =
      PhxDiff.all_versions()
      |> Enum.reverse()
      |> Enum.map_join("\n", fn version ->
        variants =
          version
          |> PhxDiff.list_sample_apps_for_version()
          |> Enum.map_join(", ", &format_app_spec(version, &1))

        "#{version}: #{variants}"
      end)

    header <> version_lines <> "\n"
  end

  defp format_app_spec(version, app_spec) do
    case app_spec.phx_new_arguments do
      [] -> "#{version}"
      args -> "#{version} #{Enum.join(args, " ")}"
    end
  end
end
