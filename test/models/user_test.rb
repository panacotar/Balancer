require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'passwords are hashed and authentication rejects incorrect passwords' do
    user = create_user
    assert user.valid_password?('test-password-only')
    assert_not user.valid_password?('incorrect')
    assert_not_equal 'test-password-only', user.encrypted_password
  end
end
