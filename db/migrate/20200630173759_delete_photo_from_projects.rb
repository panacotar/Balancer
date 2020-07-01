class DeletePhotoFromProjects < ActiveRecord::Migration[6.0]
  def change
    remove_column :projects, :photo
  end
end
