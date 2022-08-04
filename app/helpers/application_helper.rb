# frozen_string_literal: true

module ApplicationHelper
  def image_url_to_base64(url)
    album_art = nil
    img = Rails.cache.fetch(url, expires_in: 7.days, skip_nil: true) do
      HTTParty.get(url, format: :plain, headers: { "Accept-Encoding" => "gzip,deflate,br" }).body
    end

    if img.present?
      base64 = Base64.strict_encode64(img).gsub(/\s+/, "")
      album_art = "data:image/#{File.extname(url).strip.downcase[1..-1]};base64,#{Rack::Utils.escape(base64)}"
    end

    album_art
  end
end
