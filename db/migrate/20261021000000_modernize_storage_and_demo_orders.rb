class ModernizeStorageAndDemoOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :active_storage_blobs, :service_name, :string, null: false, default: 'local'
    change_column_null :active_storage_blobs, :checksum, true
    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
      t.index [:blob_id, :variation_digest], unique: true, name: 'index_active_storage_variant_records_uniqueness'
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
    add_reference :shareholders, :order, foreign_key: true, index: { unique: true }
    add_index :orders, :checkout_session_id, unique: true
    add_foreign_key :orders, :campaigns
    change_column :shareholders, :amount, :decimal, precision: 12, scale: 2, default: 0
    change_column :shareholders, :percentage, :decimal, precision: 12, scale: 6
  end
end
