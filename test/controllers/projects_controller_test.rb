require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'owner does not see edit campaign when the project has none' do
    owner = create_user(email: 'no-campaign-owner@example.com')
    project = Project.create!(project_name: 'No campaign yet', user: owner, status: false)
    attach_photo(project)
    sign_in owner

    get project_path(project)

    assert_response :success
    assert_select 'ol#project-campaign-list', count: 0
  end

  test 'owner gets an edit link for every campaign' do
    owner = create_user(email: 'has-campaign-owner@example.com')
    campaign = create_campaign_for(owner, name: 'Shown Round')
    campaign.update!(start_date: Date.current, end_date: Date.current + 30)
    later = Campaign.create!(
      name: 'Later Round',
      description: 'A short description',
      project: campaign.project,
      investment_goal: 1_000,
      equity: 10,
      status: false
    )
    attach_photo(campaign.project)
    sign_in owner

    get project_path(campaign.project)

    assert_response :success
    assert_select '#tab-product-action a[href*="/campaigns/"][href$="/edit"]', count: 0
    assert_select 'ol#project-campaign-list li' do |items|
      assert_equal ['Shown Round', 'Later Round'], items.map { |item| item.at('span').text.strip }
    end
    assert_select 'ol#project-campaign-list li a' do |links|
      assert_equal [
        edit_project_campaign_path(campaign.project, campaign),
        edit_project_campaign_path(campaign.project, later)
      ], links.map { |link| link['href'] }
      assert_equal [1, 1], links.map { |link| link.css('i.fa-pen').size }
    end
  end

  private

  def attach_photo(record)
    record.photo.attach(
      io: StringIO.new("\x89PNG\r\n\x1A\n"),
      filename: 'photo.png',
      content_type: 'image/png'
    )
  end
end
