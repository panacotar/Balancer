require 'test_helper'

class ShareholdersControllerTest < ActionDispatch::IntegrationTest
  test 'legacy GET and POST cannot bypass checkout or create pledges' do
    campaign = create_campaign
    sign_in create_user
    assert_no_difference('Shareholder.count') do
      get new_project_shareholder_path(campaign.project)
      assert_redirected_to project_path(campaign.project)
      post project_shareholders_path(campaign.project), params: { pledge_amount: 500 }
      assert_redirected_to project_path(campaign.project)
    end
  end
end
