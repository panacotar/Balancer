require 'test_helper'

class PhotoValidationTest < ActiveSupport::TestCase
  test 'users projects and campaigns reject active content and oversized photos' do
    [create_user, create_project, create_campaign].each do |record|
      record.photo.attach(io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
                          filename: 'unsafe.svg', content_type: 'image/svg+xml')
      assert_not record.valid?
      assert_includes record.errors[:photo], 'must be a JPEG, PNG or WebP image'
      record.photo.detach
      record.photo.attach(io: StringIO.new('x' * (5.megabytes + 1)),
                          filename: 'large.jpg', content_type: 'image/jpeg', identify: false)
      assert_not record.valid?
      assert_includes record.errors[:photo], 'must be 5 MiB or smaller'
    end
  end

  test 'normal uploaded images remain supported' do
    project = create_project
    attach_photo(project)
    assert project.reload.photo.attached?
    assert project.valid?
  end

  test 'declaring an SVG as JPEG does not bypass content identification' do
    project = create_project
    project.photo.attach(io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
                         filename: 'fake.jpg', content_type: 'image/jpeg')
    assert_not project.valid?
    assert_includes project.errors[:photo], 'must be a JPEG, PNG or WebP image'
  end
end
