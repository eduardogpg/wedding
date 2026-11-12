# == Schema Information
#
# Table name: guest_wishes
#
#  id         :bigint           not null, primary key
#  body       :text             not null
#  guest_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wedding_id :bigint           not null
#
# Indexes
#
#  index_guest_wishes_on_wedding_id  (wedding_id)
#
# Foreign Keys
#
#  fk_rails_...  (wedding_id => weddings.id)
#
class GuestWish < ApplicationRecord
  belongs_to :wedding

  normalizes :guest_name, :body, with: ->(value) { value.to_s.strip }

  validate :readable_message

  private

  def readable_message
    errors.add(:base, "Escribe un mensaje para los novios.") if body.blank?
    errors.add(:base, "El mensaje puede tener hasta 1000 caracteres.") if body.to_s.length > 1_000
    errors.add(:base, "El nombre puede tener hasta 80 caracteres.") if guest_name.to_s.length > 80
  end
end
