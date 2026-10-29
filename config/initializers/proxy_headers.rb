# Caddy sanitizes X-Forwarded-* headers. Ignore the client-supplied RFC 7239
# Forwarded header so Rack::Attack uses the same trusted client IP source.
Rack::Request.forwarded_priority = [:x_forwarded]
