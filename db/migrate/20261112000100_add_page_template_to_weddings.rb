class AddPageTemplateToWeddings < ActiveRecord::Migration[8.1]
  def change
    add_column :weddings, :page_template, :string, null: false, default: "botanical"
  end
end
