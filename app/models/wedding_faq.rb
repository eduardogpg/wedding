# == Schema Information
#
# Table name: wedding_faqs
#
#  id         :bigint           not null, primary key
#  answer     :text             not null
#  question   :string           not null
#  visible    :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  wedding_id :bigint           not null
#
# Indexes
#
#  index_wedding_faqs_on_wedding_id  (wedding_id)
#
# Foreign Keys
#
#  fk_rails_...  (wedding_id => weddings.id)
#
class WeddingFaq < ApplicationRecord
  belongs_to :wedding, inverse_of: :faqs

  normalizes :question, :answer, with: ->(value) { value.strip }
  validates :question, :answer, presence: true
  validates :question, length: { maximum: 200 }
  validates :answer, length: { maximum: 3_000 }

  scope :visible, -> { where(visible: true) }
end
