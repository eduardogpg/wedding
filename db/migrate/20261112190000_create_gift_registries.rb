class CreateGiftRegistries < ActiveRecord::Migration[8.1]
  def change
    create_table :gift_registries do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :store_name, null: false
      t.string :url, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
