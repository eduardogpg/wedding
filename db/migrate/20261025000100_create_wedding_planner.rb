class CreateWeddingPlanner < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :weddings do |t|
      t.string :partner_one, null: false
      t.string :partner_two, null: false
      t.string :subdomain, null: false
      t.date :wedding_date, null: false
      t.string :timezone, null: false, default: "Mexico City"
      t.integer :status, null: false, default: 0
      t.string :theme, null: false, default: "sage"
      t.string :headline, default: "Together is a beautiful place to be."
      t.text :invitation_text, null: false
      t.text :story
      t.string :dress_code
      t.date :rsvp_deadline
      t.timestamps
    end
    add_index :weddings, :subdomain, unique: true
    add_index :weddings, :wedding_date

    create_table :events do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.string :venue_name, null: false
      t.text :address
      t.string :map_url
      t.text :notes
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :rsvps do |t|
      t.references :wedding, null: false, foreign_key: true
      t.string :guest_name, null: false
      t.string :email, null: false
      t.integer :attendance, null: false
      t.integer :party_size, null: false, default: 1
      t.text :message
      t.timestamps
    end
    add_index :rsvps, [ :wedding_id, :email ], unique: true
  end
end
