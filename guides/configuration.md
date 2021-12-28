# Configuration

PhxDiff has several environment variables that need to be set to deploy to a production environment

* `OTEL_EXPORTER`
  * not set - Don't export otel metrics
  * `honeycomb` - Send the traces directly to honeycomb
  * `stdout` - Output the traces to stdout. Useful for debugging locally.

* `OTEL_HONEYCOMB_API_KEY` - The API key used to send data to honeycomb. Required when using the honeycomb OTEL exporter.
* `OTEL_HONEYCOMB_DATASET` - The honeycomb dataset to send traces to. Required when using the honeycomb OTEL exporter.
* `OTEL_SERVICE_NAME` - The name to be set on the `service.name` property on traces.
