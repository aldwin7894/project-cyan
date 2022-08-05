# frozen_string_literal: true

require "addressable/uri"

module ApplicationHelper
  def image_url_to_base64(url)
    album_art = nil
    if url.blank? then return album_art end
    filetype = Addressable::URI.parse(url).extname.remove(".")

    img = Rails.cache.fetch(url, expires_in: 1.month, skip_nil: true) do
      data = {}
      res = HTTParty.get(url, format: :plain, headers: { "Accept-Encoding" => "gzip,deflate,br" })
      ext = res.headers.content_type.split("/")
      if ext[0] == "image" || (ext[0] == "plain" && filetype == "webp")
        data[:image] = res.body
        data[:ext] = ext[1]
      end
      if %w(jpg jpeg gif png).include?(data[:ext]) && ENV.fetch("OPTIMIZE_IMAGE_ENABLED", false)
        data[:image] = Rails.configuration.x.image_optim.optimize_image_data(data[:image].to_s)
      end
      data.present? ? data : nil
    end

    if img&.[](:image).present?
      base64 = Base64.strict_encode64(img[:image]).gsub(/\s+/, "")
      album_art = "data:image/#{img[:ext]};base64,#{Rack::Utils.escape(base64)}"
    end
    album_art
  end
end
