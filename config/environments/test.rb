require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  # However, Spring requires reloading to be enabled for proper operation.
  config.enable_reloading = true

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  # Enable eager loading on CI for better test coverage
  config.eager_load = ENV["DISABLE_EAGER_LOAD"] != "true"

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  config.action_controller.enable_fragment_cache_logging = true

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Set log level to ERROR to minimize noise during testing
  # The log capture system in test_helper.rb will handle showing logs for failed tests
  config.log_level = :error

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Action Cable Logging (optional)
  # config.action_cable.logger = ActiveSupport::Logger.new(STDOUT)
  # config.action_cable.logger.level = Logger::WARN

  # Active Job Queue Adapter Configuration
  # By default, Rails uses :test adapter in test environment.
  # If needed, you can explicitly set it:
  # config.active_job.queue_adapter = :test

  # Use Solid Cache for caching with SQLite in test
  config.cache_store = :solid_cache_store, { database: :cache }
  config.solid_cache.connects_to = { database: { writing: :cache, reading: :cache } }

  # Use Solid Queue for Active Job (optional, typically not needed)
  # config.active_job.queue_adapter = :solid_queue

  # Email configuration for test environment
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.action_mailer.perform_caching = false

  # Configure allowed hosts for test environment
  config.hosts << "www.example.com"
  config.hosts << "test.host"
  config.hosts << "localhost"

  # Configure Vite for test environment
  # config.vite.autoload = false
  # config.vite.dev_server_enabled = false
end

# EEA mode now defaults to true, no environment variable needed
