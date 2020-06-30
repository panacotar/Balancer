class CreateCampaigns < ActiveRecord::Migration[6.0]
  def change
    create_table :campaigns do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date
      t.text :description
      t.boolean :status

      t.timestamps
    end
  end
end
