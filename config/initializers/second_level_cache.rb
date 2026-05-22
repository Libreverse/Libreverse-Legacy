# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# SecondLevelCache configuration for ActiveRecord caching
Rails.application.configure do
  config.after_initialize do
    # Configure SecondLevelCache settings
    SecondLevelCache.configure do |config|
      # Set cache key prefix to avoid conflicts with other cache types
      config.cache_key_prefix = "slc"

      # Enable logging for cache hits/misses (optional, can be disabled in production)
      config.logger = Rails.logger if Rails.env.development?
    end
  end
end
