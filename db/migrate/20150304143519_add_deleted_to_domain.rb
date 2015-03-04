class AddDeletedToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :deleted, :boolean, default: false
  end
end
