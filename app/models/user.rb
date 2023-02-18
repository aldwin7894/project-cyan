# frozen_string_literal: true

class User
  include Mongoid::Document
  include Mongoid::Timestamps

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

  ## Database authenticatable
  field :username, type: String, default: ""
  field :email, type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token, type: String
  field :reset_password_sent_at, type: DateTime

  ## Rememberable
  field :remember_created_at, type: DateTime

  ## Trackable
  field :sign_in_count, type: Integer, default: 0
  field :current_sign_in_at, type: DateTime
  field :last_sign_in_at, type: DateTime
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip, type: String

  ## Confirmable
  # t.string   :confirmation_token
  # t.datetime :confirmed_at
  # t.datetime :confirmation_sent_at
  # t.string   :unconfirmed_email # Only if using reconfirmable

  ## Lockable
  # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
  # t.string   :unlock_token # Only if unlock strategy is :email or :both
  # t.datetime :locked_at

  field :status, type: Integer, default: 1

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
