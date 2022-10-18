# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register "image/jpeg", :jpg
Mime::Type.register "image/png", :png
Mime::Type.register "application/pdf", :pdf
Mime::Type.register "image/svg+xml", :svg
Mime::Type.register "application/manifest+json", :webmanifest
Mime::Type.register "image/webp", :webp
Rack::Mime::MIME_TYPES[".webp"] = "image/webp"
