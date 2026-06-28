require "active_support/core_ext/integer/time"
require "re2"

Rails.application.configure do
  # Prepare the ingress controller used to receive mail
  # config.action_mailbox.ingress = :relay

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Always serve precompiled static files from `public/`.
  config.public_file_server.enabled = false

  # Vite JS/fonts/images via B2 + Cloudflare when enabled at runtime (Docker sets VITE_ASSETS_B2_ENABLED).
  if ENV["VITE_ASSETS_B2_ENABLED"].to_s.match?(/\A(1|true|yes|on)\z/i)
    config.asset_host = ENV.fetch("B2_ASSETS_PUBLIC_URL") do
      "https://libreverse-legacy-static.libreverse.io/file/libreverse-legacy-assets"
    end
  end

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Provide explicit X-Accel mapping to Rack::Sendfile so it can translate
  # filesystem paths to the internal NGINX locations without relying on
  # request headers. Keep trailing slashes for correct prefix substitution.
  storage_fs  = Rails.root.join("storage/").to_s
  storage_uri = "/_internal/storage/"
  private_fs  = Rails.root.join("private/").to_s
  private_uri = "/_internal/private/"
  config.middleware.swap Rack::Sendfile, Rack::Sendfile, "X-Accel-Redirect", [
    [ storage_fs, storage_uri ],
    [ private_fs, private_uri ]
  ]

  # Active Storage: store files in the database using active_storage_db
  config.active_storage.service = :db

  # Action Cable Configuration
  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "https://your-production-domain.com", /https:\/\/your-production-domain.*/ ]

  # Host Authorization - using centralized configuration
  allowed_hosts = LibreverseInstance::Application.allowed_hosts

  # Always allow localhost and 127.0.0.1 with and without port for healthchecks
  %w[localhost 127.0.0.1 localhost:3000 127.0.0.1:3000].each do |local_host|
    allowed_hosts << local_host unless allowed_hosts.include?(local_host)
  end

  # Add additional hosts from ENV if present (but keep localhost hosts)
  if ENV["ALLOWED_HOSTS"].present?
    env_hosts = ENV["ALLOWED_HOSTS"].split(",").map(&:strip)
    env_hosts.each { |host| allowed_hosts << host unless allowed_hosts.include?(host) }
  end

  config.hosts.clear
  allowed_hosts.each { |host| config.hosts << host }

  # CORS origins (for rack-cors or similar middleware)
  config.x.cors_origins = ENV["CORS_ORIGINS"] if ENV["CORS_ORIGINS"].present?

  # EEA_MODE flag (for app logic)
  config.x.eea_mode = ENV["EEA_MODE"] == "true" if ENV["EEA_MODE"].present?

  # SSL Enforcement (using centralized configuration, but allow ENV override)
  ssl_enabled = if ENV["FORCE_SSL"].present?
    ENV["FORCE_SSL"] == "true"
  else
    LibreverseInstance::Application.force_ssl?
  end

  config.assume_ssl = ssl_enabled
  config.force_ssl  = ssl_enabled

  # Log level (using centralized configuration, but allow ENV override)
  config.log_level = if ENV["RAILS_LOG_LEVEL"].present?
    ENV["RAILS_LOG_LEVEL"].to_sym
  else
    LibreverseInstance::Application.rails_log_level
  end

  # Use default Rails log file location for production
  # config.paths["log"] = "/dev/null"

  # Cache Store Configuration (coder provided by initializer)
  config.cache_store = :solid_cache_store

  # Active Job Queue Adapter Configuration
  config.active_job.queue_adapter = :solid_queue
  # Ensure Solid Queue uses the dedicated :queue database configuration
  config.solid_queue.connects_to = { database: { writing: :queue } }
  # TiDB compatibility: disable SKIP LOCKED which requires a suitable unique key pattern
  # and has caused protocol errors in TiDB with Trilogy in our polling queries.
  config.solid_queue.use_skip_locked = false
  # config.active_job.queue_name_prefix = "libreverse_instance_production"

  # I18n Fallbacks
  config.i18n.fallbacks = true

  # Deprecation Notices
  config.active_support.deprecation = :notify
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # --- Use CookieStore (Permanent Change) ---
  config.session_store :cookie_store,
                       key: "_libreverse_session",
                       secure: config.force_ssl,
                       httponly: true,
                       expire_after: 2.hours,
                       same_site: :strict # Keep security settings
  # ----------------------------------------

  # Email configuration for production
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS") { "localhost" },
    port: ENV.fetch("SMTP_PORT") { "587" }.to_i,
    domain: ENV.fetch("SMTP_DOMAIN") { LibreverseInstance.instance_domain },
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION") { "plain" },
    enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO") { "true" } == "true",
    openssl_verify_mode: ENV.fetch("SMTP_OPENSSL_VERIFY_MODE") { "peer" }
  }
  config.action_mailer.default_url_options = {
    host: ENV.fetch("MAILER_HOST") { LibreverseInstance.instance_domain },
    protocol: "https"
  }
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false

  # Active Record Encryption setup for console1984
  # This uses a key generator based on secret_key_base for local/dev/test
  key_generator = ActiveSupport::KeyGenerator.new(
    Rails.application.secret_key_base, iterations: 1000
  )
  config.active_record.encryption.primary_key = key_generator.generate_key("active_record_encryption_primary", 32).unpack1("H*")
  config.active_record.encryption.deterministic_key = key_generator.generate_key("active_record_encryption_deterministic", 32).unpack1("H*")
  config.active_record.encryption.key_derivation_salt = "AR"
  config.active_record.encryption.support_unencrypted_data = true
  config.active_record.encryption.encrypt_fixtures = true
  config.active_record.encryption.store_key_references = false
end
