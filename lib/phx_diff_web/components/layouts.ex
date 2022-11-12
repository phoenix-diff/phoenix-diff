defmodule PhxDiffWeb.Layouts do
  @moduledoc false
  use PhxDiffWeb, :html

  import PhxDiffWeb.AnalyticsComponents

  embed_templates "layouts/*"
end
