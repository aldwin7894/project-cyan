# frozen_string_literal: true

module ApplicationHelper
  def asset_data_uri(path)
    asset = Rails.application.assets.find_asset path

    throw "Could not find asset '#{path}'" if asset.nil?

    base64 = Base64.encode64(asset.to_s).gsub(/\s+/, "")
    "data:#{asset.content_type};base64,#{Rack::Utils.escape(base64)}"
  end
end
