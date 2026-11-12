class AddCelebrationLanding < ActiveRecord::Migration[8.1]
  def change
    add_column :weddings, :celebration_starts_at, :datetime
    add_column :weddings, :landing_mode, :integer, null: false, default: 0

    create_table :guest_wishes do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :guest_name
      t.text :body, null: false
      t.timestamps
    end

    create_table :guest_photos do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :guest_name
      t.text :caption
      t.timestamps
    end
  end
end
