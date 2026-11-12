# == Schema Information
#
# Table name: gift_registries
#
#  id         :bigint           not null, primary key
#  position   :integer          default(0), not null
#  store_name :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wedding_id :bigint           not null
#
# Indexes
#
#  index_gift_registries_on_wedding_id  (wedding_id)
#
# Foreign Keys
#
#  fk_rails_...  (wedding_id => weddings.id)
#
class GiftRegistry < ApplicationRecord
  belongs_to :wedding, inverse_of: :gift_registries

  normalizes :store_name, :url, with: ->(value) { value.strip }

  validates :store_name, :url, presence: true
  validates :store_name, length: { maximum: 80 }
  validates :url, length: { maximum: 500 }
  validate :safe_url

  private

  def safe_url
    return if url.blank?

    uri = URI.parse(url)
    errors.add(:url, "debe ser una dirección HTTPS completa") unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    errors.add(:url, "debe ser una dirección HTTPS completa")
  end
end
