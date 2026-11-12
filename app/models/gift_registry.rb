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
