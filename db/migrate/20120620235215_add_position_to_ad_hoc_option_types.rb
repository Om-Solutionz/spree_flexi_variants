class AddPositionToAdHocOptionTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ad_hoc_option_types, :position, :integer, default: 0
  end
end
