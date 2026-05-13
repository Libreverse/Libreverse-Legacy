# Consolidate and apply all security headers at once
base_headers = {
  "X-Content-Type-Options" => "nosniff",
  "X-XSS-Protection" => "1; mode=block",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Cross-Origin-Opener-Policy" => "same-origin",
  "Cross-Origin-Resource-Policy" => "same-origin",
  "Expect-CT" => "max-age=86400, enforce",
  "X-Download-Options" => "noopen",
  "X-Permitted-Cross-Domain-Policies" => "none"
}

# Conditionally merge HSTS based on production environment
base_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains" if Rails.env.production?

SECURE_HEADERS = base_headers.freeze

Rails.application.config.action_dispatch.default_headers.merge!(SECURE_HEADERS)
