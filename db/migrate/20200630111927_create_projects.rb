class CreateProjects < ActiveRecord::Migration[6.0]
  def change
    create_table :projects do |t|
      t.string :project_name
      t.string :category
      t.text :vision
      t.text :pitch
      t.string :target
      t.boolean :status
      t.string :photo
      t.references :users, null: false, foreign_key: true

      t.timestamps
    end
  end
end
