# Configuration

PhxDiff has several environment variables that need to be set to deploy to a production environment

* `RENDER_TRACKING_SCRIPTS` - Render the google analytics tracking scripts in the template when `"true"`.
* `OTEL_EXPORTER`
  * not set - Don't export otel metrics
  * `honeycomb` - Send the traces directly to honeycomb
  * `signoz-local` - Send the traces to a local instance of signoz
  * `stdout` - Output the traces to stdout. Useful for debugging locally.

* `OTEL_HONEYCOMB_API_KEY` - The API key used to send data to honeycomb. Required when using the honeycomb OTEL exporter.
* `OTEL_HONEYCOMB_DATASET` - The honeycomb dataset to send traces to. Required when using the honeycomb OTEL exporter.
* `OTEL_SERVICE_NAME` - The name to be set on the `service.name` property on traces.
* `URL_SCHEME` - Scheme of generated urls. Defaults to `"https"`.
* `URL_HOST` - Host of generated urls. Defaults to `"www.phoenixdiff.org"`.
* `URL_PORT` - Port of generated urls. Defaults to `443`.
* `ASSET_SCHEME` - Overrides scheme of asset urls. Defaults to the same as `URL_SCHEME`.
* `ASSET_HOST` - Overrides host of asset urls. Defaults to the same as `URL_HOST`.
* `ASSET_PORT` - Overrides port of asset urls. Defaults to the same as `URL_PORT`.
