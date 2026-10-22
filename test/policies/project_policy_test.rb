require 'test_helper'

class ProjectPolicyTest < ActiveSupport::TestCase
  test 'only owners can edit and only administrators can destroy' do
    project = create_project
    assert ProjectPolicy.new(project.user, project).update?
    assert_not ProjectPolicy.new(create_user, project).update?
    assert_not ProjectPolicy.new(nil, project).create?
    assert_not ProjectPolicy.new(project.user, project).destroy?
    assert ProjectPolicy.new(create_user(admin: true), project).destroy?
  end
end
