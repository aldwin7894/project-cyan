# frozen_string_literal: true

class User < ApplicationRecord
  has_one_attached :photo
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
    :recoverable,
    :rememberable,
    :trackable,
    :validatable,
    authentication_keys: [:username],
    reset_password_keys: [:username]

  before_create :set_defaults

  def set_defaults
    self.reset_password_token = SecureRandom.urlsafe_base64
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  # use this instead of email_changed? for Rails = 5.1.x
  def will_save_change_to_email?
    false
  end
end
