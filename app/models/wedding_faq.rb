class WeddingFaq < ApplicationRecord
  belongs_to :wedding, inverse_of: :faqs

  normalizes :question, :answer, with: ->(value) { value.strip }
  validates :question, :answer, presence: true
  validates :question, length: { maximum: 200 }
  validates :answer, length: { maximum: 3_000 }

  scope :visible, -> { where(visible: true) }
end
