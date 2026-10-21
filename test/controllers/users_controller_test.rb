require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'sign in dashboard and sign out work with current Devise' do
    user = create_user
    post user_session_path, params: { user: { email: user.email, password: 'test-password-only' } }
    assert_response :redirect
    get dashboard_path
    assert_response :success
    assert_select 'h2', text: 'Hello Demo Tester'
    delete destroy_user_session_path
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test 'invalid sign in does not authenticate' do
    user = create_user
    post user_session_path, params: { user: { email: user.email, password: 'wrong-password' } }
    assert_response :unprocessable_entity
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test 'registration permits the required profile fields' do
    assert_difference('User.count') do
      post user_registration_path, params: { user: {
        email: 'new-founder@example.test', password: 'test-password-only', password_confirmation: 'test-password-only',
        first_name: 'New', last_name: 'Founder', address: 'Demo City', gender: 'others',
        date_of_birth: '1990-01-01', phone_number: 'new-founder-only'
      } }
    end
    get dashboard_path
    assert_response :success
  end
end
