module ApplicationHelper
  # Cloudinary transformation options stay available; local demo/test uploads use Rails URLs.
  def attachment_image_tag(attachment, **options)
    return image_tag('avatar_balancer.png', **options.slice(:class, :alt, :id)) unless attachment.attached?

    if attachment.blob.service_name == 'cloudinary'
      cl_image_tag(attachment.key, **options)
    else
      image_tag(attachment, **options.slice(:class, :alt, :id, :data, :width, :height))
    end
  end
end
