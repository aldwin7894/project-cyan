# frozen_string_literal: true

require "sendgrid/mailer"

class DeviseCustomMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers

  def reset_password_instructions(record, token, opts = {})
    # send_forgot_password_email(record, token)
  end
end
