class AddUnknownToDomain < ActiveRecord::Migration
  def change
    add_column :domains, :unknown, :boolean, default: false
  end
end
