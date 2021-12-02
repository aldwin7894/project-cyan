# frozen_string_literal: true

module Tinifiable
  extend ActiveSupport::Concern

  included do
    require "tinify"
  end

  def tinify_from_url(url: "")
    logger.tagged("Tinifiable") {
      logger.info "Starting compression from URL source: #{url}."
    }

    # Get the source of the uploaded image.
    source = Tinify.from_url(url)
    # Encode to remove space and make it a valid uri
    url    = URI.encode(url)
    # Get path of now valid uri, revert to spaces to match the filename.
    path   = URI.parse(url).path.gsub("%20", " ")
    # on compress store image on path to overwrite
    source.store(
      service:               "s3",
      aws_access_key_id:     Rails.application.credentials.dig(:aws, :access_key_id),
      aws_secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key),
      region:                "ap-southeast-1",
      path:                  "#{S3_BUCKET.name}#{path}"
    )

    logger.tagged("Tinifiable") {
      logger.info "Completed compression of #{url}."
    }
  rescue Tinify::AccountError => e
    puts "The error message is: " + e.message
    # Verify your API key and account limit.
  rescue Tinify::ClientError => e
    puts "The error message is: " + e.message
    # Check your source image and request options.
  rescue Tinify::ServerError => e
    puts "The error message is: " + e.message
    # Temporary issue with the Tinify API.
  rescue Tinify::ConnectionError => e
    puts "The error message is: " + e.message
    # A network connection error occurred.
  rescue => e
    puts "The error message is: " + e.message
  end
end
