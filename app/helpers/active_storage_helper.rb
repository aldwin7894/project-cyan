# frozen_string_literal: true

module ActiveStorageHelper
  include Tinifiable

  def move_s3_attachment(blob, target_key)
    current_key = blob.key
    # Retrieve S3 Configuration.
    config      = YAML.load_file(Rails.root.join("config", "storage.yml"))
    # Get the object to move from the bucket.
    obj_to_move = S3_BUCKET.object(current_key)
    # Copy the attachment to the specified new_key.
    obj_to_move.copy_to(bucket: S3_BUCKET.name, key: target_key)
    # Delete permanently the old file to avoid cluttering the root folder.
    obj_to_move.delete(version_id: obj_to_move.version_id)
    # Update the blob key from the database.
    update_blob_key(blob, target_key)

    logger.tagged("Active Storage Helper", blob.filename) {
      logger.info "Successfully moved #{current_key} to #{target_key}."
    }
  rescue => e
    logger.tagged("Active Storage Helper", blob.filename) {
      logger.error "A problem has been encountered while moving #{blob.filename} to #{target_key}. #{e.full_message}"
    }
  end

  private
    def update_blob_key(blob, new_key)
      if blob.update!(key: new_key)
        # Compress the image using tinify.
        tinify_from_url(url: blob.service_url)
      end
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
