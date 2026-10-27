module ValidatedPhoto
  extend ActiveSupport::Concern

  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_BYTES = 5.megabytes

  included do
    validate :acceptable_photo
  end

  private

  def acceptable_photo
    return unless photo.attached?

    errors.add(:photo, 'must be a JPEG, PNG or WebP image') unless CONTENT_TYPES.include?(photo.blob.content_type)
    errors.add(:photo, 'must be 5 MiB or smaller') if photo.blob.byte_size > MAX_BYTES
  end
end
