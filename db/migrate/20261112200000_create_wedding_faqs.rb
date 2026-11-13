class CreateWeddingFaqs < ActiveRecord::Migration[8.1]
  def change
    create_table :wedding_faqs do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :question, null: false
      t.text :answer, null: false
      t.boolean :visible, null: false, default: true
      t.timestamps
    end
  end
end
