class DirectUploadsController < ActiveStorage::DirectUploadsController
  before_action :authenticate_user!
  rate_limit to: 20, within: 1.hour, only: :create,
             store: AuthenticationRateLimits::STORE, with: -> { head :too_many_requests }

  def create
    attributes = blob_args
    size = Integer(attributes[:byte_size], exception: false)
    unless size&.positive? && size <= ValidatedPhoto::MAX_BYTES &&
           ValidatedPhoto::CONTENT_TYPES.include?(attributes[:content_type])
      return head :unprocessable_entity
    end

    super
  end
end
