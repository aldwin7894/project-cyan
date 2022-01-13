# frozen_string_literal: true

# This module is being included to ActiveStorage::Attachment upon initialization in
# /config/initializers/prepare.rb.
module AttachmentMovable
  extend ActiveSupport::Concern

  included do
    include ActiveStorageHelper

    after_commit :process_image
  end

  private
    def process_image
      # Optimize image only if the existing key doesn't
      # have S3_BUCKET_ENV on it, meaning it has been uploaded.
      unless blob.key.include?(S3_BUCKET_ENV) && blob.image?
        new_key = "web/#{S3_BUCKET_ENV}/uploads/#{self.record_type.downcase}/#{blob.key}"

        # optimize image and upload to new key
        optimized = optimize_image(blob)
        move_to_uploads(blob, new_key, optimized)
      end
    end
end
