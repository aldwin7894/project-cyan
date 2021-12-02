# frozen_string_literal: true

# This module is being included to ActiveStorage::Attachment upon initialization in
# /config/initializers/prepare.rb.
module AttachmentMovable
  extend ActiveSupport::Concern

  included do
    include ActiveStorageHelper

    after_save :move_attachment
  end

  private
    def move_attachment
      # Initiate a move only if the existing key doesn't
      # have S3_BUCKET_ENV on it, meaning it has been updated.
      unless blob.key.include?(S3_BUCKET_ENV)
        new_key = "web/#{S3_BUCKET_ENV}/uploads/#{self.record_type.downcase}/#{blob.key}"
        # We will access ActiveStorage::Attachment's blob and record type.
        move_s3_attachment(blob, new_key)
      end
    end
end
