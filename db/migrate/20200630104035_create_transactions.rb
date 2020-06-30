class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.string :category
      t.integer :amount
      t.string :status
      t.references :users, null: false, foreign_key: true

      t.timestamps
    end
  end
end
