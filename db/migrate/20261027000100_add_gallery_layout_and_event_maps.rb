class AddGalleryLayoutAndEventMaps < ActiveRecord::Migration[8.1]
  def change
    add_column :weddings, :gallery_layout, :string, null: false, default: "carousel"
    add_column :events, :show_map, :boolean, null: false, default: true
    add_column :events, :map_embed_url, :text
  end
end
