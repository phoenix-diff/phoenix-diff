defmodule PhxDiffWeb.AnalyticsComponents do
  @moduledoc false

  use Phoenix.Component

  attr :tracking_id, :string, required: true

  def google_analytics(assigns) do
    ~H"""
    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

      ga('create', '<%= @tracking_id %>', 'auto');
      ga('send', 'pageview');
    </script>
    """
  end

  def honeybadger_error_tracking(assigns) do
    ~H"""
    <script src="//js.honeybadger.io/v6.5/honeybadger.min.js" type="text/javascript">
    </script>

    <script type="text/javascript">
      Honeybadger.configure({
        apiKey: '<%= @honeybadger.api_key %>',
        environment: '<%= @honeybadger.environment_name %>',
        revision: '<%= @honeybadger.revision %>'
      });
    </script>
    """
  end
end
