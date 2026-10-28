class Event < ApplicationRecord
  GOOGLE_MAP_HOSTS = %w[www.google.com google.com maps.google.com].freeze

  belongs_to :wedding, inverse_of: :events

  validates :title, :starts_at, :venue_name, presence: true
  validates :title, :venue_name, length: { maximum: 160 }
  validates :address, :notes, length: { maximum: 1_000 }
  validates :map_embed_url, length: { maximum: 4_096 }
  validate :safe_map_url
  validate :safe_map_embed_url

  # Google Maps' "Copy HTML" includes an iframe. Store only its source URL;
  # pasted markup is never rendered on a wedding page.
  normalizes :map_embed_url, with: ->(value) {
    value = value.strip
    value.start_with?("<") ? (Nokogiri::HTML.fragment(value).at_css("iframe")&.[]("src") || value) : value
  }

  def map_link
    map_url.presence || "https://www.google.com/maps/search/?api=1&#{URI.encode_www_form(query: [ venue_name, address ].compact.join(', '))}"
  end

  def google_maps_embed_url
    map_embed_url.presence || "https://www.google.com/maps?#{URI.encode_www_form(q: [venue_name, address].compact_blank.join(', '), output: 'embed')}"
  end

  private

  def safe_map_url
    return if map_url.blank?

    uri = URI.parse(map_url)
    errors.add(:map_url, "must be a full HTTPS address") unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    errors.add(:map_url, "must be a full HTTPS address")
  end

  def safe_map_embed_url
    return if map_embed_url.blank?

    uri = URI.parse(map_embed_url)
    valid = uri.is_a?(URI::HTTPS) && GOOGLE_MAP_HOSTS.include?(uri.host) &&
      uri.port == 443 && uri.userinfo.nil? &&
      (uri.path == "/maps/embed" || uri.path.match?(%r{\A/maps/embed/v1/(place|view|directions|search|streetview)\z}))
    errors.add(:map_embed_url, "must come from Google Maps → Share → Embed a map") unless valid
  rescue URI::InvalidURIError
    errors.add(:map_embed_url, "must be a valid Google Maps embed URL or iframe code")
  end
end
