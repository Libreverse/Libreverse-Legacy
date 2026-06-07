ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

# Ensure proper setup for Mocha
Mocha.configure do |c|
  c.stubbing_non_existent_method = :prevent
  c.stubbing_method_unnecessarily = :prevent
end

# Log capture system for tests - only show logs for failing tests
module TestLogCapture
  @original_logger = nil
  @current_test_logs = nil
  @capture_enabled = false
  @original_logdev = nil
  @original_level = nil
  @original_verbose = nil
  @original_stdout = nil
  @original_stderr = nil
  @stdout_buffer = nil
  @stderr_buffer = nil

  def self.setup
    return if @original_logger

    @original_logger = Rails.logger.dup
  end

  def self.enable_capture
    @capture_enabled = true
  end

  def self.disable_capture
    @capture_enabled = false
  end

  def self.start_capture_for_test
    return unless @original_logger && @capture_enabled

    # Create a string buffer to capture logs
    @current_test_logs = StringIO.new

    # Also capture STDOUT/STDERR to silence noisy gems that write directly to them
    @original_stdout = $stdout
    @original_stderr = $stderr
    @stdout_buffer = StringIO.new
    @stderr_buffer = StringIO.new
    $stdout = @stdout_buffer
    $stderr = @stderr_buffer

    # Instead of replacing the logger, we'll intercept its output by replacing the log device
    # This preserves all the logger's functionality including tagged logging
    if @original_logger.respond_to?(:instance_variable_get)
      # For TaggedLogging, we need to access the underlying logger
      underlying_logger = @original_logger
      underlying_logger = @original_logger.instance_variable_get(:@logger) if @original_logger.is_a?(ActiveSupport::TaggedLogging)

      # Store the original log device so we can restore it later
      @original_logdev = underlying_logger.instance_variable_get(:@logdev)

      # Replace the log device with our string buffer
      new_logdev = Logger::LogDevice.new(@current_test_logs)
      underlying_logger.instance_variable_set(:@logdev, new_logdev)

      # Set debug level to capture all logs during test
      @original_level = underlying_logger.level
      underlying_logger.level = Logger::DEBUG
    else
      # Fallback: create a new logger if we can't modify the existing one
      buffer_logger = ActiveSupport::Logger.new(@current_test_logs)
      buffer_logger.level = Logger::DEBUG
      buffer_logger.extend(ActiveSupport::LoggerSilencer) unless buffer_logger.respond_to?(:silence)
      buffer_logger = ActiveSupport::TaggedLogging.new(buffer_logger)

      buffer_logger.formatter = @original_logger.formatter if @original_logger.respond_to?(:formatter) && @original_logger.formatter

      Rails.logger = buffer_logger
    end

    # Silence noisy gems that write directly to STDOUT/STDERR
    silence_noisy_gems
  end

  def self.silence_noisy_gems
    # Silence sitemap generator output completely in test environment
    if defined?(SitemapGenerator)
      # Monkey-patch various SitemapGenerator classes to silence all output
      if defined?(SitemapGenerator::Builder::SitemapFile)
        SitemapGenerator::Builder::SitemapFile.class_eval do
          def log(action, name = nil, link_count = nil)
            # Silence all sitemap file logging in test environment
          end
        end
      end

      if defined?(SitemapGenerator::SitemapIndexFile)
        SitemapGenerator::SitemapIndexFile.class_eval do
          def log(*args)
            # Silence sitemap index logging
          end
        end
      end

      if defined?(SitemapGenerator::Sitemap)
        SitemapGenerator::Sitemap.class_eval do
          def self.verbose
            false # Always return false in test environment
          end

          def self.verbose=(value)
            # Ignore attempts to set verbose to true in test environment
          end
        end
      end
    end

    # Suppress Ruby warnings about frozen string literals in test environment
    original_verbose = $VERBOSE
    $VERBOSE = nil
    # NOTE: $VERBOSE will be restored in finish_capture_for_test
    @original_verbose = original_verbose
  end

  def self.finish_capture_for_test(test_instance, test_name)
    return unless @original_logger

    # Add safety check to prevent NoMethodError on nil arrays
    begin
      # Restore original verbose setting
      $VERBOSE = @original_verbose if @original_verbose

      # Restore original STDOUT/STDERR
      if @original_stdout && @original_stderr
        $stdout = @original_stdout
        $stderr = @original_stderr
        @original_stdout = nil
        @original_stderr = nil
        @stdout_buffer = nil
        @stderr_buffer = nil
      end

      # Restore original logger/log device
      if @capture_enabled
        if @original_logdev && @original_logger.respond_to?(:instance_variable_get)
          # Restore the original log device and level
          underlying_logger = @original_logger
          underlying_logger = @original_logger.instance_variable_get(:@logger) if @original_logger.is_a?(ActiveSupport::TaggedLogging)

          underlying_logger.instance_variable_set(:@logdev, @original_logdev)
          underlying_logger.level = @original_level if @original_level

          @original_logdev = nil
          @original_level = nil
        else
          # Fallback: restore the original logger reference
          Rails.logger = @original_logger
        end
      end

      # Check if test passed by examining the test instance
      test_passed = true
      if test_instance.respond_to?(:passed?) && !test_instance.passed?
        test_passed = false
      elsif test_instance.respond_to?(:failure) && test_instance.failure
        test_passed = false
      elsif test_instance.respond_to?(:failures) && test_instance.failures.any?
        test_passed = false
      end

      # Only output captured logs if the test failed
      if !test_passed && @current_test_logs && @capture_enabled
        captured_logs = @current_test_logs.string
        if captured_logs.present?
          # Restore stdout first so we can output the logs
          original_stdout = $stdout
          $stdout = @original_stdout if @original_stdout

          puts "\n#{'=' * 80}"
          puts "LOGS FOR FAILED TEST: #{test_name}"
          puts "=" * 80
          puts captured_logs
          puts "#{'=' * 80}\n"

          # Restore the buffer if needed
          $stdout = original_stdout unless @original_stdout
        end
      end

      # Clean up
      @current_test_logs = nil
      @original_verbose = nil
    rescue StandardError => e
      # Log any cleanup errors
      puts "Warning: TestLogCapture cleanup error (#{e.class}: #{e.message}), continuing..."
    end
  end
end

CI_TEST_RUN = ENV["CI"].present? || ENV["GITHUB_ACTIONS"].present?

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # Mocha does not play nicely with Minitest's parallel testing, leading to
    # `NoMethodError: undefined method 'pop' for nil` during teardown. Running
    # tests sequentially avoids this interference.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Set up log capture for each test - but disable during fixture loading
    setup do
      unless CI_TEST_RUN
        TestLogCapture.setup
        # Enable capture only after fixtures are loaded
        TestLogCapture.enable_capture
        TestLogCapture.start_capture_for_test
      end
    end

    # Finish log capture after each test
    teardown do
      unless CI_TEST_RUN
        test_name = "#{self.class.name}##{method_name}"
        TestLogCapture.finish_capture_for_test(self, test_name) if TestLogCapture.respond_to?(:finish_capture_for_test)
        TestLogCapture.disable_capture if TestLogCapture.respond_to?(:disable_capture)
      end
    rescue StandardError => e
      puts "Warning: Test teardown error (#{e.class}: #{e.message}), continuing..."
    end

    # Add more helper methods to be used by all tests here...

    # Mock asset path helpers for tests to avoid Vite dependency issues
    def self.mock_asset_helpers
      ApplicationHelper.class_eval do
        def seo_asset_path(path)
          # Return a mock path for tests to avoid Vite errors
          if path.is_a?(String)
            if path.start_with?("@")
              "/test-assets/#{path.sub('@', '')}"
            elsif path.start_with?("~/")
              "/test-assets/#{path.sub('~/', '')}"
            else
              path
            end
          else
            path
          end
        end

        def seo_config_with_assets(key)
          # Return mock config for tests
          config = begin
                     Rails.application.config.x.seo_config[key.to_s]
          rescue StandardError
                     {}
          end
          if config.is_a?(Hash)
            config.transform_values { |v| v.is_a?(String) ? seo_asset_path(v) : v }
          else
            config
          end
        end
      end

      # Mock emoji renderer to avoid Vite asset issues
      return unless defined?(Emoji::Renderer)

        Emoji::Renderer.class_eval do
          def self.build_img_tag(emoji)
            %(<span class="emoji-test">#{emoji}</span>)
          end

          def self.replace(text)
            text.to_s.gsub(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/) do |emoji|
              %(<span class="emoji-test">#{emoji}</span>)
            end
          end
        end
    end

    # Call the mock setup
    mock_asset_helpers

    # Helper method to disable fixtures for tests that don't need them
    def self.no_fixtures
      # This method prevents fixture loading for this test class
      self.use_transactional_tests = false
      self.fixture_sets = []
    end
  end
end

# Override ApplicationController methods for tests
module ActionController
  class TestCase
    # Define helper method to set up authentication state
    setup do
      # Don't stub rodauth in tests - it's handled in the PasswordSecurityEnforcer concern
    end
  end
end

# Modify PasswordSecurityEnforcer module to always skip in tests
module PasswordSecurityEnforcer
  def enforce_password_security
    return if Rails.env.test?

    super
  end
end
