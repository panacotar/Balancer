module PhotoUploadLimits
  extend ActiveSupport::Concern

  included do
    rate_limit to: 20, within: 1.hour, only: %i[create update], scope: 'photo_uploads',
               by: -> { current_user.id }, store: AuthenticationRateLimits::STORE,
               if: -> { params[controller_name.singularize].try(:[], :photo).present? },
               with: -> { head :too_many_requests }
  end
end
