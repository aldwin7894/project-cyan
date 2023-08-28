require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/all"

if ENV.fetch("SIGNOZ_ENABLED", "false") == "true"
  OpenTelemetry::SDK.configure do |c|
    c.use_all
  end
end
