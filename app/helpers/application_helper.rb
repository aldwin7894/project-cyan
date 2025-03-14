# frozen_string_literal: true
# typed: true

require "addressable/uri"
require "brotli"

module ApplicationHelper
  IMAGE_FILETYPES = ["jpg", "jpeg", "gif", "png", "webp"]
  def cached_image_url_to_base64(url)
    image = nil
    return image if url.blank?

    filetype = Addressable::URI.parse(url).extname.remove(".")

    img = Rails.cache.fetch("IMAGES/#{url}", expires_in: 3.months, skip_nil: true) do
      data = {}
      res = HTTParty.get(
        url,
        format: :plain,
        headers: { "Accept-Encoding" => "br,gzip,deflate" },
        timeout: 30,
        open_timeout: 10
      )
      break unless res.success?

      ext = res.headers&.content_type&.split("/")
      if ext[0] == "image" || IMAGE_FILETYPES.include?(filetype)
        data[:image] = res.body
        data[:ext] = ext[1]
      end

      break if data.blank?

      data
    end

    return image if img.blank?

    base64 = Base64.strict_encode64(img[:image]).gsub(/\s+/, "")
    image = "data:image/#{img[:ext]};base64,#{Rack::Utils.escape(base64)}"
    image
  rescue StandardError
    nil
  end

  def vite_url_to_base64(url)
    image = nil
    ext = T.let(nil, T.untyped)
    return image if url.blank?

    asset = Rails.cache.fetch("ASSETS/#{url}", skip_nil: true) do
      res = HTTParty.get(
        url,
        format: :plain,
        headers: { "Accept-Encoding" => "br,gzip,deflate" },
        timeout: 30,
        open_timeout: 10
      )
      break unless res.success?
      ext = res.headers&.content_type

      { data: res.body, ext: }
    end

    return url unless asset.present? && asset[:ext].present?

    base64 = Base64.strict_encode64(asset[:data]).gsub(/\s+/, "")
    image = "data:#{asset[:ext]};base64,#{Rack::Utils.escape(base64)}"
    image
  rescue StandardError
    nil
  end

  def anilist_progress_text(activity)
    return if activity.blank?

    if ["completed", "rewatched"].include? activity["status"].strip
      return activity["status"].capitalize
    end

    "#{activity["status"].capitalize} #{activity["progress"].to_s.split(" - ").last}"
  end
end
