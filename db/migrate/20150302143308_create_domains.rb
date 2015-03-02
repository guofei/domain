class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :url
      t.datetime :expires_on

      t.timestamps null: false
    end
    add_index :domains, :url, unique: true
  end
end
