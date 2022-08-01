# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = Rails.configuration.x.feature.lograge
  config.lograge.keep_original_rails_log = false
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.base_controller_class = ["ActionController::Base"]
  config.lograge.ignore_actions = [
    "HealthCheck::HealthCheckController#index",
    "HomeController#ping"
  ]

  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    {
      request_time: Time.zone.now.strftime("%B %e, %Y %r"),
      application: ::Rails.application.class.module_parent,
      process_id: Process.pid,
      host: event.payload[:host],
      remote_ip: event.payload[:remote_ip],
      ip: event.payload[:ip],
      x_forwarded_for: event.payload[:x_forwarded_for],
      headers: event.payload[:headers].env.select do |k|
                 k.match("^HTTP.*|^CONTENT.*|^AUTHORIZATION.*") &&
                   %w[ENVOY NEWRELIC HTTP_COOKIE].all? { |x| k.exclude?(x) }
               end,
      params: event.payload[:params].except(*exceptions).to_json,
      rails_env: Rails.env,
      exception: event.payload[:exception]&.first,
      request_id: event.payload[:headers]["action_dispatch.request_id"],
      exception_message: "'#{event.payload[:exception]&.last}'",
      exception_backtrace: event.payload[:exception_object]&.backtrace&.join(","),
    }.compact
  end
end
