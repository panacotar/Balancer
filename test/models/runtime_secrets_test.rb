require 'test_helper'
require 'tempfile'

class RuntimeSecretsTest < ActiveSupport::TestCase
  test 'file secrets load before configuration and empty optional files are ignored' do
    Tempfile.create('balancer-secret') do |file|
      file.write("a-test-secret\n")
      file.flush
      env = { 'SECRET_KEY_BASE_FILE' => file.path }
      RuntimeSecrets.load!(env)
      assert_equal 'a-test-secret', env['SECRET_KEY_BASE']
      file.truncate(0)
      env = { 'CLOUDINARY_URL_FILE' => file.path }
      RuntimeSecrets.load!(env)
      assert_nil env['CLOUDINARY_URL']
    end
  end
end
