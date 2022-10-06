# frozen_string_literal: true

module ActiveStorageHelper
  def optimize_image(blob)
    url = nil

    blob.open do |file|
      url = ImageOptim.new(config_paths: "config/image_optim.yml").optimize_image(file).to_s
    end

    url
  end

  # def move_to_uploads(blob, new_key, optimized)
  #   old_key = blob.key
  #   # Get the object to move from the bucket.
  #   old_object = S3_BUCKET.object(old_key)
  #   # Upload optimized image to new_key
  #   S3_BUCKET.object(new_key).upload_file(optimized)
  #   # Delete permanently the old file to avoid cluttering the root folder.
  #   old_object.delete(version_id: old_object.version_id)
  #   # Update the blob key from the database.
  #   update_blob_key(blob, new_key, optimized)

  #   logger.tagged("Active Storage Helper", blob.filename) {
  #     logger.info "Successfully moved #{old_key} to #{new_key}."
  #   }
  # rescue => e
  #   logger.tagged("Active Storage Helper", blob.filename) {
  #     logger.error "A problem has been encountered while moving #{blob.filename} to #{target_key}. #{e.full_message}"
  #   }
  # end

  private
    def update_blob_key(blob, new_key, optimized)
      blob.update!(
        key: new_key,
        checksum: Digest::MD5.base64digest(File.read(optimized))
      )
    rescue => e
      logger.tagged("Active Storage Helper", blob.filename) {
        logger.error "A problem has been encountered while updating #{blob.filename}'s key to #{target_key}. #{e.full_message}"
      }
    end

    def logger
      logger           = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = ::Logger::Formatter.new

      ActiveSupport::TaggedLogging.new(logger)
    end
end
