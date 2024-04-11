defmodule PhxDiffWeb.CompareLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket
  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets

  defmodule NotFoundError do
    defexception plug_status: 404

    def message(_) do
      "Not found"
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:no_changes?, false)}
  end

  @impl true
  def handle_params(%{"diff_specification" => diff_specification}, _uri, socket) do
    with {:ok, diff_specification} <- PhxDiffWeb.Params.decode_diff_spec(diff_specification),
         {:ok, socket} <-
           fetch_and_assign_diff_when_connected(
             socket,
             diff_specification.source,
             diff_specification.target
           ) do
      socket = assign_app_specs(socket, diff_specification.source, diff_specification.target)
      {:noreply, socket}
    else
      _ ->
        raise NotFoundError
    end
  end

  @spec assign_app_specs(Socket.t(), AppSpecification.t(), AppSpecification.t()) :: Socket.t()
  def assign_app_specs(socket, source_app_spec, target_app_spec) do
    socket
    |> assign(:source_app_spec, source_app_spec)
    |> assign(:target_app_spec, target_app_spec)
    |> assign(:page_title, page_title(source_app_spec, target_app_spec))
    |> assign(:source_url, github_url(source_app_spec))
    |> assign(:target_url, github_url(target_app_spec))
    |> assign(:source_version, source_app_spec.phoenix_version)
    |> assign(:target_version, target_app_spec.phoenix_version)
  end

  @spec fetch_and_assign_diff_when_connected(
          Socket.t(),
          AppSpecification.t(),
          AppSpecification.t()
        ) :: {:ok, Socket.t()} | {:error, Changeset.t()}
  defp fetch_and_assign_diff_when_connected(socket, source_app_spec, target_app_spec) do
    with {:ok, diff} <- PhxDiff.fetch_diff(source_app_spec, target_app_spec) do
      {:ok,
       socket
       |> assign(:diff, diff)
       |> assign(:no_changes?, diff == "")}
    end
  end

  defp page_title(%AppSpecification{} = source, %AppSpecification{} = target) do
    "v#{source.phoenix_version} to v#{target.phoenix_version}"
  end

  @github_url "https://github.com/phoenix-diff/phoenix-diff/tree/master/priv/data/sample-app/"
  defp github_url(%{phx_new_arguments: arguments, phoenix_version: version}) do
    @github_url <> Path.join(to_string(version), phx_argument_path(arguments))
  end

  defp phx_argument_path(arguments) do
    case PhxNewArgListPresets.preset_from_arg_list(arguments) do
      {:ok, %PhxNewArgListPresets.PhxNewArgListPreset{path: path}} -> path
      _ -> "default"
    end
  end
end
