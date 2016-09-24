class CreateMuseums < ActiveRecord::Migration
  def change
    create_table :museums do |t|
      t.string :name
      t.integer :type
      t.string :url
      t.time :open_time
      t.time :close_time
      t.string :sleep
      t.string :address
      t.boolean :del_flg
      t.references :pref, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
