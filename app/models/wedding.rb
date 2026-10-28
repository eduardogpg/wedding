class Wedding < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[app www admin api mail support assets localhost dashboard].freeze
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  THEMES = { "sage" => "Garden sage", "rose" => "Dusty rose", "blue" => "Something blue" }.freeze
  MAX_PHOTO_SIZE = 10.megabytes

  has_many :events, -> { order(:starts_at, :position, :id) }, dependent: :destroy, inverse_of: :wedding
  has_many :rsvps, dependent: :destroy
  has_one_attached :cover_photo
  has_many_attached :gallery_photos
  accepts_nested_attributes_for :events, allow_destroy: true,
    reject_if: ->(attrs) { attrs.except("id", "_destroy", "position").values.all?(&:blank?) }

  enum :status, { draft: 0, published: 1 }, default: :draft
  normalizes :subdomain, with: ->(value) { value.strip.downcase }

  validates :partner_one, :partner_two, :wedding_date, :subdomain, :invitation_text, presence: true
  validates :partner_one, :partner_two, length: { maximum: 80 }
  validates :subdomain, uniqueness: true, length: { in: 3..63 },
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "can only contain lowercase letters, numbers, and single hyphens" },
    exclusion: { in: RESERVED_SUBDOMAINS, message: "is reserved; please choose another address" }
  validates :theme, inclusion: { in: THEMES.keys }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :headline, length: { maximum: 150 }
  validates :invitation_text, :story, length: { maximum: 10_000 }
  validates :dress_code, length: { maximum: 160 }
  validate :deadline_before_wedding
  validate :acceptable_photos

  scope :chronological, -> { order(:wedding_date, :id) }
  scope :upcoming, -> { where(wedding_date: Date.current..) }

  def couple_names
    "#{partner_one} & #{partner_two}"
  end

  def initials
    [ partner_one, partner_two ].map { |name| name.to_s.first&.upcase }.join(" & ")
  end

  def accepting_rsvps?
    published? && wedding_date >= Date.current && (rsvp_deadline.nil? || rsvp_deadline >= Date.current)
  end

  def confirmed_guests
    rsvps.attending.sum(:party_size)
  end

  private

  def deadline_before_wedding
    if rsvp_deadline && wedding_date && rsvp_deadline > wedding_date
      errors.add(:rsvp_deadline, "must be on or before the wedding date")
    end
  end

  def acceptable_photos
    errors.add(:gallery_photos, "can include up to 20 photos") if gallery_photos.size > 20
    ([ cover_photo.attachment ].compact + gallery_photos.to_a).each do |photo|
      errors.add(:base, "Photos must be JPEG, PNG, or WebP") unless PHOTO_TYPES.include?(photo.blob.content_type)
      errors.add(:base, "Each photo must be 10 MB or smaller") if photo.blob.byte_size > MAX_PHOTO_SIZE
    end
  end
end
