# == Schema Information
#
# Table name: weddings
#
#  id                    :bigint           not null, primary key
#  celebration_starts_at :datetime
#  dress_code            :string
#  gallery_layout        :string           default("carousel"), not null
#  headline              :string           default("Juntos es un lugar hermoso.")
#  invitation_text       :text             not null
#  landing_mode          :integer          default("automatic"), not null
#  page_template         :string           default("botanical"), not null
#  partner_one           :string           not null
#  partner_two           :string           not null
#  rsvp_deadline         :date
#  status                :integer          default("draft"), not null
#  story                 :text
#  subdomain             :string           not null
#  theme                 :string           default("sage"), not null
#  timezone              :string           default("Mexico City"), not null
#  wedding_date          :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_weddings_on_subdomain     (subdomain) UNIQUE
#  index_weddings_on_wedding_date  (wedding_date)
#
class Wedding < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[app www admin api mail support assets localhost dashboard].freeze
  PHOTO_TYPES = %w[image/jpeg image/png image/webp].freeze
  THEMES = { "sage" => "Salvia", "rose" => "Rosa empolvado", "blue" => "Azul novia" }.freeze
  GALLERY_LAYOUTS = { "carousel" => "Carrusel de fotos", "grid" => "Cuadrícula de fotos" }.freeze
  PAGE_TEMPLATES = {
    "botanical" => { name: "Botánico", description: "Un arco ilustrado y un aire de jardín." },
    "editorial" => { name: "Editorial", description: "Una portada grande y un diseño de revista." },
    "classic" => { name: "Clásico", description: "Una invitación centrada, con un marco atemporal." }
  }.freeze
  MAX_PHOTO_SIZE = 10.megabytes

  has_many :events, -> { order(:starts_at, :position, :id) }, dependent: :destroy, inverse_of: :wedding
  has_many :faqs, -> { order(:id) }, class_name: "WeddingFaq", dependent: :destroy, inverse_of: :wedding
  has_many :rsvps, dependent: :destroy
  has_many :guest_wishes, dependent: :destroy
  has_many :guest_photos, dependent: :destroy
  has_many :gift_registries, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :wedding
  has_one_attached :cover_photo
  has_many_attached :gallery_photos
  accepts_nested_attributes_for :events, allow_destroy: true,
    reject_if: :unused_schedule_entry?
  accepts_nested_attributes_for :gift_registries, allow_destroy: true,
    reject_if: ->(attributes) { attributes["id"].blank? && attributes["store_name"].blank? && attributes["url"].blank? }

  accepts_nested_attributes_for :faqs, allow_destroy: true,
    reject_if: ->(attributes) { attributes["id"].blank? && attributes["question"].blank? && attributes["answer"].blank? }

  enum :status, { draft: 0, published: 1 }, default: :draft
  enum :landing_mode, { automatic: 0, invitation: 1, live: 2 }, default: :automatic, prefix: :landing, validate: true
  normalizes :subdomain, with: ->(value) { value.strip.downcase }

  validates :partner_one, :partner_two, :wedding_date, :subdomain, :invitation_text, presence: true
  validates :partner_one, :partner_two, length: { maximum: 80 }
  validates :subdomain, uniqueness: true, length: { in: 3..63 },
    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "solo puede tener letras minúsculas, números y guiones simples" },
    exclusion: { in: RESERVED_SUBDOMAINS, message: "está reservada; elige otra dirección" }
  validates :theme, inclusion: { in: THEMES.keys }
  validates :gallery_layout, inclusion: { in: GALLERY_LAYOUTS.keys }
  validates :page_template, inclusion: { in: PAGE_TEMPLATES.keys }
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

  # When the public link should leave the invitation and open photo uploads and wishes.
  # An explicit time wins. Otherwise the first scheduled event does. With neither, the
  # wedding date opens the party page at the beginning of that day in the wedding's zone.
  def celebration_begins_at
    return celebration_starts_at if celebration_starts_at.present?

    first_start = persisted? ? events.minimum(:starts_at) : events.filter_map(&:starts_at).min
    first_start || wedding_date.in_time_zone(timezone).beginning_of_day
  end

  def celebration_open?(at = Time.current)
    return true if landing_live?
    return false if landing_invitation?

    at >= celebration_begins_at
  end

  def hero_photo
    cover_photo.attached? ? cover_photo.blob : gallery_photos.first&.blob
  end

  private

  def unused_schedule_entry?(attrs)
    return false if attrs["id"].present?

    title_is_placeholder = attrs["title"].blank? || %w[ceremony reception].include?(attrs["title"].strip.downcase)
    title_is_placeholder && attrs.except("id", "_destroy", "position", "show_map", "title").values.all?(&:blank?)
  end

  def deadline_before_wedding
    if rsvp_deadline && wedding_date && rsvp_deadline > wedding_date
      errors.add(:rsvp_deadline, "debe ser el mismo día de la boda o antes")
    end
  end

  def acceptable_photos
    errors.add(:base, "Puedes incluir hasta 20 fotos.") if gallery_photos.size > 20
    ([ cover_photo.attachment ].compact + gallery_photos.to_a).each do |photo|
      errors.add(:base, "Las fotos deben ser JPEG, PNG o WebP.") unless PHOTO_TYPES.include?(photo.blob.content_type)
      errors.add(:base, "Cada foto debe pesar 10 MB o menos.") if photo.blob.byte_size > MAX_PHOTO_SIZE
    end
  end
end
