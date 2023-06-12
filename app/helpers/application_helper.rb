# frozen_string_literal: true

require "addressable/uri"

module ApplicationHelper
  IMAGE_FILETYPES = ["jpg", "jpeg", "gif", "png", "webp"]
  def cached_image_url_to_base64(url)
    image = nil
    return image if url.blank?

    filetype = Addressable::URI.parse(url).extname.remove(".")

    img = Rails.cache.fetch("IMAGES/#{url}", expires_in: 1.week, skip_nil: true) do
      data = {}
      res = HTTParty.get(
        url,
        format: :plain,
        headers: { "Accept-Encoding" => "gzip,deflate,br" },
        timeout: 10
      )
      return if res.code >= 300

      ext = res.headers&.content_type&.split("/")
      if ext[0] == "image" || IMAGE_FILETYPES.include?(filetype)
        data[:image] = res.body
        data[:ext] = ext[1]
      end

      data.presence ? data : nil
    end

    return url if img.blank?

    base64 = Base64.strict_encode64(img[:image]).gsub(/\s+/, "")
    image = "data:image/#{img[:ext]};base64,#{Rack::Utils.escape(base64)}"
    image
  rescue StandardError
    nil
  end

  def vite_url_to_base64(url)
    image = nil
    ext = nil
    return image if url.blank?

    asset = Rails.cache.fetch("ASSETS/#{url}", expires_in: 1.month, skip_nil: true) do
      res = HTTParty.get(
        url,
        format: :plain,
        headers: { "Accept-Encoding" => "gzip,deflate,br" },
        timeout: 10
      )
      return if res.code >= 300
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

    if activity["status"].strip === "completed"
      return activity["status"].capitalize
    end

    "#{activity["status"].capitalize} #{activity["progress"].to_s.split(" - ").last}"
  end
end
