require 'application_system_test_case'

class DemoTest < ApplicationSystemTestCase
  setup do
    @user = create_user
    @project = create_project(user: @user)
    attach_photo(@project)
    @campaign = create_campaign(project: @project)
    4.times { create_campaign(project: create_project) }
  end

  def login
    visit new_user_session_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: 'test-password-only'
    click_button 'Login'
    assert_selector '.navbar .dropdown-toggle'
  end

  test 'navigation carousels forms and pledge modal work without JavaScript errors' do
    visit root_path
    assert_selector '.responsive.slick-initialized'
    click_link 'Campaigns', match: :first
    assert_selector '#cards-campaign .card'
    assert_no_selector '#chartdiv'
    login
    visit project_path(@project)
    find('[data-target="#project-pledge-modal"]').click
    assert_selector '#project-pledge-modal.show'
    assert_selector '#pledge-amount'
    find('#project-pledge-modal [data-dismiss="modal"]', match: :first).click
    assert_no_selector '#project-pledge-modal.show'
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == 'SEVERE' }
  end

  test 'dashboard chart survives navigation and upload form retains date pickers' do
    login
    visit dashboard_path
    assert_selector '#chartdiv svg'
    click_link 'Campaigns', match: :first
    assert_selector '#cards-campaign'
    visit new_project_campaign_path(@project)
    assert_selector '.flatpickr-input', visible: :all
    visit new_project_path
    fill_in 'Project name', with: 'Browser upload project'
    select 'Education', from: 'Category'
    fill_in 'Vision', with: 'A better community'
    fill_in 'Pitch', with: 'Help us grow'
    fill_in 'Target', with: 'Everyone'
    attach_file 'Photo', Rails.root.join('app/assets/images/bg_buswoman.jpg')
    click_button 'Create Project'
    assert_text 'A better community'
    assert_current_path project_path(Project.find_by!(project_name: 'Browser upload project'))
    assert_selector 'img[src*="/rails/active_storage/"]'
    assert_empty page.driver.browser.logs.get(:browser).select { |entry| entry.level == 'SEVERE' }
  end
end
