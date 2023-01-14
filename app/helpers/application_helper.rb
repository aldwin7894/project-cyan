# frozen_string_literal: true

require "addressable/uri"

module ApplicationHelper
  IMAGE_FILETYPES = ["jpg", "jpeg", "gif", "png", "webp"]
  def image_url_to_base64(url)
    image = nil
    return image if url.blank?

    filetype = Addressable::URI.parse(url).extname.remove(".")

    img = Rails.cache.fetch(url, expires_in: 1.month, skip_nil: true) do
      data = {}
      res = HTTParty.get(url, format: :plain, headers: { "Accept-Encoding" => "gzip,deflate,br" })
      ext = res.headers&.content_type&.split("/")
      if ext[0] == "image" || IMAGE_FILETYPES.include?(filetype)
        data[:image] = res.body
        data[:ext] = ext[1]
      end
      if %w(jpg jpeg gif png).include?(data[:ext]) && ENV.fetch("OPTIMIZE_IMAGE_ENABLED", false)
        data[:image] = Rails.configuration.x.image_optim.optimize_image_data(data[:image].to_s)
      end
      data.presence ? data : nil
    end

    if img&.[](:image).present?
      base64 = Base64.strict_encode64(img[:image]).gsub(/\s+/, "")
      image = "data:image/#{img[:ext]};base64,#{Rack::Utils.escape(base64)}"
    end
    image
  rescue StandardError
    nil
  end
end
