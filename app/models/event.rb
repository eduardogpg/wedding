class Event < ApplicationRecord
  belongs_to :wedding, inverse_of: :events

  validates :title, :starts_at, :venue_name, presence: true
  validates :title, :venue_name, length: { maximum: 160 }
  validates :address, :notes, length: { maximum: 1_000 }
  validate :safe_map_url

  def map_link
    map_url.presence || "https://www.google.com/maps/search/?api=1&#{URI.encode_www_form(query: [ venue_name, address ].compact.join(', '))}"
  end

  private

  def safe_map_url
    return if map_url.blank?

    uri = URI.parse(map_url)
    errors.add(:map_url, "must be a full HTTPS address") unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    errors.add(:map_url, "must be a full HTTPS address")
  end
end
