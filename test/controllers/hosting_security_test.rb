require 'test_helper'

class HostingSecurityTest < ActionDispatch::IntegrationTest
  setup { AuthenticationRateLimits::STORE.clear }
  teardown { AuthenticationRateLimits::STORE.clear }

  test 'login attempts are throttled without exposing account existence' do
    10.times { post user_session_path, params: { user: { email: 'unknown@example.test', password: 'wrong' } } }
    post user_session_path, params: { user: { email: 'unknown@example.test', password: 'wrong' } }
    assert_response :too_many_requests
  end

  test 'password recovery is generic and throttled' do
    user = create_user
    post user_password_path, params: { user: { email: user.email } }
    known_message = flash[:notice]
    post user_password_path, params: { user: { email: 'unknown@example.test' } }
    assert_equal known_message, flash[:notice]
    3.times { post user_password_path, params: { user: { email: 'unknown@example.test' } } }
    post user_password_path, params: { user: { email: 'unknown@example.test' } }
    assert_response :too_many_requests
  end

  test 'registration is throttled' do
    5.times { post user_registration_path, params: { user: { email: '', password: '' } } }
    post user_registration_path, params: { user: { email: '', password: '' } }
    assert_response :too_many_requests
  end

  test 'direct uploads require authentication and reject invalid metadata' do
    path = '/rails/active_storage/direct_uploads'
    attributes = { filename: 'image.jpg', byte_size: 100, checksum: Base64.strict_encode64('checksum'), content_type: 'image/jpeg' }
    assert_no_difference 'ActiveStorage::Blob.count' do
      post path, params: { blob: attributes }
      assert_redirected_to new_user_session_path
    end
    sign_in create_user
    assert_no_difference 'ActiveStorage::Blob.count' do
      post path, params: { blob: attributes.merge(byte_size: 5.megabytes + 1) }
      assert_response :unprocessable_entity
      post path, params: { blob: attributes.merge(content_type: 'image/svg+xml') }
      assert_response :unprocessable_entity
    end
    assert_difference 'ActiveStorage::Blob.count', 1 do
      post path, params: { blob: attributes }
      assert_response :success
    end
  end

  test 'health endpoint checks database availability' do
    get '/healthcheck'
    assert_response :success
    ActiveRecord::Base.connection_pool.stub(:with_connection, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) do
      get '/healthcheck'
      assert_response :service_unavailable
    end
  end

  test 'multipart image writes are throttled per account across projects and campaigns' do
    user = create_user
    sign_in user
    project = create_project(user: user)
    upload = Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/bg_buswoman.jpg'), 'image/jpeg')
    20.times do
      patch project_path(project), params: { project: { photo: upload } }
      assert_response :redirect
    end
    post project_campaigns_path(project), params: { campaign: { photo: upload } }
    assert_response :too_many_requests
  end

  test 'pages carry CSP without allowing arbitrary scripts or frames' do
    get root_path
    assert_response :success
    assert_includes response.headers['Content-Security-Policy'], "script-src 'self'"
    assert_includes response.headers['Content-Security-Policy'], "object-src 'none'"
    assert_includes response.headers['Content-Security-Policy'], "frame-ancestors 'self'"
  end
end
