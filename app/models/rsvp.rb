# == Schema Information
#
# Table name: rsvps
#
#  id         :bigint           not null, primary key
#  attendance :integer          not null
#  email      :string           not null
#  guest_name :string           not null
#  message    :text
#  party_size :integer          default(1), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wedding_id :bigint           not null
#
# Indexes
#
#  index_rsvps_on_wedding_id            (wedding_id)
#  index_rsvps_on_wedding_id_and_email  (wedding_id,email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (wedding_id => weddings.id)
#
class Rsvp < ApplicationRecord
  belongs_to :wedding
  enum :attendance, { attending: 0, declined: 1 }, validate: true
  normalizes :email, with: ->(value) { value.strip.downcase }

  validates :guest_name, :email, :attendance, presence: true
  validates :guest_name, length: { maximum: 160 }
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { scope: :wedding_id, message: "ya respondió a esta boda. Escribe al planner para hacer un cambio." }
  validates :party_size, numericality: { only_integer: true, in: 1..10 }
  validates :message, length: { maximum: 1_000 }
end
