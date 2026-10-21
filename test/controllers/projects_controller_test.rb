require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test 'public project is visible but creating a project requires login' do
    project = create_project
    get project_path(project)
    assert_response :success
    get new_project_path
    assert_redirected_to new_user_session_path
  end

  test 'only the owner can edit or update a project' do
    owner = create_user
    project = create_project(user: owner)
    sign_in create_user
    get edit_project_path(project)
    assert_response :forbidden
    patch project_path(project), params: { project: { project_name: 'Stolen' } }
    assert_response :forbidden
    assert_not_equal 'Stolen', project.reload.project_name
    sign_in owner
    patch project_path(project), params: { project: { project_name: 'Updated garden' } }
    assert_redirected_to project_path(project)
    assert_equal 'Updated garden', project.reload.project_name
  end

  test 'authenticated founder can publish a project with a photo' do
    owner = create_user
    sign_in owner
    assert_difference('Project.count') do
      post projects_path, params: { commit: 'Publish', project: {
        project_name: 'New community project', category: 'Education', vision: 'A better future',
        pitch: 'Grow together', target: 'Everyone',
        photo: fixture_file_upload(Rails.root.join('app/assets/images/bg_buswoman.jpg'), 'image/jpeg')
      } }
    end
    project = Project.last
    assert_equal owner, project.user
    assert project.photo.attached?
    assert_equal 'test', project.photo.blob.service_name
    get project_path(project)
    assert_response :success
    assert_select 'img[src*="/rails/active_storage/"]'
  end
end
