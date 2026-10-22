require 'test_helper'

class CloudinaryUploadsTest < ActionDispatch::IntegrationTest
  test 'Cloudinary 2 adapter uploads and renders transformed images with current Active Storage' do
    original_cloud = Cloudinary.config.cloud_name
    Cloudinary.config.cloud_name = 'demo'
    project = create_project
    uploaded = false
    uploader = lambda do |io, **options|
      assert_operator io.size, :>, 0
      assert options[:public_id].present?
      assert options[:context][:checksum].present?
      uploaded = true
      { 'public_id' => options[:public_id] }
    end
    Cloudinary::Uploader.stub(:upload_large, uploader) do
      File.open(Rails.root.join('app/assets/images/bg_buswoman.jpg')) do |file|
        blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: 'demo.jpg',
                                                     content_type: 'image/jpeg', service_name: 'cloudinary')
        project.photo.attach(blob)
      end
    end
    assert uploaded
    get project_path(project)
    assert_response :success
    assert_select 'img[src*="res.cloudinary.com/demo/image/upload/"][src*="c_fill"]'
  ensure
    Cloudinary.config.cloud_name = original_cloud
  end
end
