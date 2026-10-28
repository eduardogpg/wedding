class Rsvp < ApplicationRecord
  belongs_to :wedding
  enum :attendance, { attending: 0, declined: 1 }, validate: true
  normalizes :email, with: ->(value) { value.strip.downcase }

  validates :guest_name, :email, :attendance, presence: true
  validates :guest_name, length: { maximum: 160 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { scope: :wedding_id, message: "has already responded to this wedding. Please contact the planner to make changes." }
  validates :party_size, numericality: { only_integer: true, in: 1..10 }
  validates :message, length: { maximum: 1_000 }
end
