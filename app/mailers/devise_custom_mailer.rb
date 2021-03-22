# frozen_string_literal: true

class DeviseCustomMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers

  def reset_password_instructions(record, token, opts = {})
    # send_forgot_password_email(record, token)
  end
end
