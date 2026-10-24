# frozen_string_literal: true
# typed: true

## This class extends devise to validate the JWT provided by cloudflare and ensure the email addresses match

class CfAccessAuthenticatable < Devise::Strategies::Authenticatable
  def valid?
    # Valid if either the Cloudflare header or the cookie is present
    request.headers["Cf-Access-Jwt-Assertion"].present? || request.cookies["CF_Authorization"].present?
  end

  def authenticate!
    # Prioritize the recommended header, fallback to cookie
    token = request.headers["Cf-Access-Jwt-Assertion"] || request.cookies["CF_Authorization"]

    unless token.present?
      Rails.logger.info("Cloudflare Access JWT token not found in header or cookie")
      return fail!(:missing_token) # Let Devise failure app handle it
    end

    jwk_loader = lambda do |options|
      @cached_keys = nil if options[:invalidate]
      @cached_keys ||= keys
    end

    payload, = JWT.decode(token, nil, true, {
                            nbf_leeway: 30, # allowed drift in seconds
                            exp_leeway: 30, # allowed drift in seconds
                            iss: cf_teams_url,
                            verify_iss: true,
                            aud: cf_aud,
                            verify_aud: true,
                            verify_iat: true,
                            algorithm: "RS256",
                            jwks: jwk_loader
                          })
    email = payload["email"]

    resource = User.find_by(email:)
    unless resource
      Rails.logger.info("User #{email} not found")
      redirect!(cf_teams_url)
      return
    end

    remember_me(resource)
    resource.after_database_authentication
    success!(resource)
  rescue JWT::DecodeError => e
    Rails.logger.error("JWT Decode Error: #{e.message}")
    redirect!(cf_teams_url)
  end

  private
    def cf_aud
      Rails.application.credentials.config.dig(:CF_JWT_AUD)
    end

    def cf_teams_url
      Rails.application.credentials.config.dig(:CF_TEAMS_URL)
    end

    def keys
      @keys ||= HTTParty.get("#{cf_teams_url}/cdn-cgi/access/certs").deep_symbolize_keys!
    end
end

Warden::Strategies.add(:cf_jwt, CfAccessAuthenticatable)
