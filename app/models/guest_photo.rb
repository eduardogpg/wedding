# == Schema Information
#
# Table name: guest_photos
#
#  id         :bigint           not null, primary key
#  caption    :text
#  guest_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wedding_id :bigint           not null
#
# Indexes
#
#  index_guest_photos_on_wedding_id  (wedding_id)
#
# Foreign Keys
#
#  fk_rails_...  (wedding_id => weddings.id)
#
class GuestPhoto < ApplicationRecord
  belongs_to :wedding
  has_many_attached :images

  normalizes :guest_name, :caption, with: ->(value) { value.to_s.strip }

  validate :acceptable_images

  private

  def acceptable_images
    if images.blank?
      errors.add(:base, "Elige al menos una foto.")
      return
    end

    errors.add(:base, "Puedes compartir hasta 10 fotos a la vez.") if images.size > 10
    images.each do |image|
      errors.add(:base, "Las fotos deben ser JPEG, PNG o WebP.") unless Wedding::PHOTO_TYPES.include?(image.blob.content_type)
      errors.add(:base, "Cada foto debe pesar 10 MB o menos.") if image.blob.byte_size > Wedding::MAX_PHOTO_SIZE
    end
  end
end
