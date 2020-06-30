class ChangeForeignKeysInMessages < ActiveRecord::Migration[6.0]
  def change
    remove_column :messages, :user_sender_id
    remove_column :messages, :user_receiver_id
  end
end
