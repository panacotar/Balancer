class CreateShareholders < ActiveRecord::Migration[6.0]
  def change
    create_table :shareholders do |t|
      t.integer :amount
      t.float :percentage
      t.boolean :status
      t.references :users, null: false, foreign_key: true
      t.references :campaigns, null: false, foreign_key: true

      t.timestamps
    end
  end
end
