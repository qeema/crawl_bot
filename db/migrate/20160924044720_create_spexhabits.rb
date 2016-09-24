class CreateSpexhabits < ActiveRecord::Migration
  def change
    create_table :spexhabits do |t|
      t.string :name
      t.string :url
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :del_flg
      t.integer :status
      t.references :museum, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
