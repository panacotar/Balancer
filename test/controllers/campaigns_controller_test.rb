require 'test_helper'

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  test 'empty catalogue renders without a campaign' do
    get campaigns_path
    assert_response :success
  end

  test 'postgres search finds matching campaign and handles no matches' do
    campaign = create_campaign(name: 'Solar community', description: 'Renewable energy for everyone')
    create_campaign(name: 'Different project', description: 'An unrelated subject')
    get campaigns_path, params: { query: 'renewable' }
    assert_response :success
    assert_select '#cards-campaign .card-title', text: campaign.name.capitalize
    assert_select '#cards-campaign .card-title', count: 1
    get campaigns_path, params: { query: 'zzznomatch' }
    assert_redirected_to campaigns_path
    assert_equal 'No search results were found', flash[:notice]
  end

  test 'campaign creation and editing require ownership' do
    campaign = create_campaign
    sign_in create_user
    get new_project_campaign_path(campaign.project)
    assert_response :forbidden
    patch project_campaign_path(campaign.project, campaign), params: { campaign: { name: 'Stolen' } }
    assert_response :forbidden
    assert_not_equal 'Stolen', campaign.reload.name
    sign_in campaign.project.user
    patch project_campaign_path(campaign.project, campaign), params: { campaign: { name: 'Owner updated' } }
    assert_redirected_to project_path(campaign.project)
    assert_equal 'Owner updated', campaign.reload.name
  end
end
