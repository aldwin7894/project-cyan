# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval, :blob
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, :ws, :wss

    # Preventing ClickJacking
    policy.frame_ancestors :self

    if Rails.env.development? || Rails.env.test?
      policy.connect_src(*policy.connect_src, :http)
      policy.script_src(*policy.script_src, :http)
      policy.img_src(*policy.img_src, :http)
      policy.style_src(*policy.style_src, :http)
    else
      # Ensure that all requests will be sent over HTTPS with no fallback to HTTP.
      policy.upgrade_insecure_requests
    end

    #     # Specify URI for violation reports
    #     # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  # config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  # config.content_security_policy_nonce_directives = %w(script-src)

  # Report CSP violations to a specified URI. See:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  # config.content_security_policy_report_only = true
end
