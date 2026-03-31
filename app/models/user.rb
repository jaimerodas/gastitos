class User < ApplicationRecord
  has_secure_password
  has_many :transactions, foreign_key: :created_by_id, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_create :auto_approve_first_user

  private

  def auto_approve_first_user
    return if User.exists?

    self.admin = true
    self.approved = true
  end
end
