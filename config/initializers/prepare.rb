# frozen_string_literal: true

Rails.configuration.to_prepare do
  ActiveStorage::Attachment.send(:include, ::AttachmentMovable)
end
