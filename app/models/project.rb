class Project < ApplicationRecord
  belongs_to :users, class_name: "User" # overwrite from the table project
end
