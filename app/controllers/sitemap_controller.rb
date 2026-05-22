require "digest"
require "stringio"

# Custom adapter for SitemapGenerator to keep sitemaps in memory
class InMemoryAdapter
  attr_reader :data

  def initialize
    @data = {}
  end

  def write(location, raw_data)
    Rails.logger.debug "InMemoryAdapter writing: #{location.path_in_public}"

    raise "Location is nil" if location.nil?
    raise "Location path_in_public is nil" if location.path_in_public.nil?
    raise "Raw data is nil" if raw_data.nil?
    raise "Raw data is empty" if raw_data.empty?

    @data[location.path_in_public] = StringIO.new
    @data[location.path_in_public].write(raw_data)
    @data[location.path_in_public].rewind

    Rails.logger.debug "Successfully wrote #{raw_data.length} bytes to #{location.path_in_public}"
  rescue StandardError => e
    Rails.logger.error "Error in InMemoryAdapter#write: #{e.class.name}: #{e.message}"
    raise e
  end

  def gzip?
    false
  end
end

class SitemapController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection

  # Serve /sitemap.xml dynamically using sitemap_generator
  def show
    Rails.logger.info "Starting sitemap generation"

    begin
  # Set the host dynamically
  host = InstanceSetting.get("canonical_host") || request.base_url
 raise "Host cannot be blank" if host.blank?
 raise "Invalid host format" unless host.match?(%r{\Ahttps?://[a-zA-Z0-9.-]+(?::\d+)?\z})

      Rails.logger.debug "Sitemap host being used: #{host.inspect}"
      Rails.logger.debug "InstanceSetting canonical_host: #{InstanceSetting.get('canonical_host').inspect}"

      # Cache the sitemap for 1 hour, with cache key based on host and experience count/last update
      # Use a single query to get both count and max updated_at to reduce DB round-trips
      stats = Experience.approved.select("COUNT(*) AS cnt, MAX(updated_at) AS max_updated").first
      raise "Failed to query Experience stats" if stats.nil?

      count = stats.cnt || 0
      last_updated = stats.max_updated
      timestamp = last_updated ? last_updated.to_i : 0
      cache_key = "sitemap/#{host}/#{count}/#{timestamp}"

      Rails.logger.debug "Cache key: #{cache_key}"

      # Generate ETag for conditional requests
      etag = Digest::MD5.hexdigest(cache_key)
      raise "Failed to generate ETag" if etag.blank?

      # Set cache headers
      # Skip cache headers in development to avoid masking application errors
      expires_in 1.hour, public: true unless Rails.env.development?

      # Handle conditional requests using stale?
      # stale? sets response.etag, checks freshness, and sends 304 if appropriate.
      # It also respects the public: true option for cache control.
      # Skip ETags in development to avoid masking application errors
      return unless Rails.env.development? || stale?(etag: etag, public: true)

      # Always force cache miss in development for easier debugging
      if Rails.env.development?
        Rails.logger.info "FORCING CACHE MISS in development mode"
        Rails.cache.delete(cache_key)
      end

      # If stale (or no ETag in request), generate and render content
      xml = if Rails.env.development?
        # Skip cache entirely in development to avoid masking bugs
        Rails.logger.info "DEVELOPMENT MODE - generating fresh sitemap content (no cache)"
        result = generate_dynamic_sitemap(host)
        raise "Sitemap generation returned nil or empty content" if result.blank?

        result
      else
        # Use cache in production for performance
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          Rails.logger.info "CACHE MISS - generating fresh sitemap content"
          result = generate_dynamic_sitemap(host)
          raise "Sitemap generation returned nil or empty content" if result.blank?

          result
        end
      end

      raise "XML content is blank after cache fetch" if xml.blank?

      Rails.logger.info "Successfully generated sitemap (#{xml.length} bytes)"

      # `plain:` skips the implicit `to_xml` call and keeps the body untouched
      render plain: xml, content_type: "application/xml; charset=utf-8"
    rescue StandardError => e
      Rails.logger.error "Sitemap generation failed: #{e.class.name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    # If fresh, stale? has already sent head :not_modified and returned false,
    # so the block is skipped and controller action effectively ends here.
  end

  private

  def self.sitemap_mutex
    @sitemap_mutex ||= Mutex.new
  end
  private_class_method :sitemap_mutex

   def generate_dynamic_sitemap(host)
     Rails.logger.info "Generating dynamic sitemap for host: #{host}"

     # Temporarily configure sitemap_generator
     original_host = SitemapGenerator::Sitemap.default_host
     original_adapter = SitemapGenerator::Sitemap.adapter
     original_compress = SitemapGenerator::Sitemap.compress

     begin
      self.class.sitemap_mutex.synchronize do
        Rails.logger.debug "Acquired sitemap mutex lock"

        SitemapGenerator::Sitemap.default_host = host
        raise "Failed to set SitemapGenerator host" if SitemapGenerator::Sitemap.default_host != host

        # Use our custom in-memory adapter and disable compression
        adapter = InMemoryAdapter.new
        raise "Failed to create InMemoryAdapter" if adapter.nil?

        SitemapGenerator::Sitemap.adapter = adapter
        SitemapGenerator::Sitemap.compress = false

        Rails.logger.debug "SitemapGenerator configured with host: #{SitemapGenerator::Sitemap.default_host}"

        # Create sitemap in memory
        SitemapGenerator::Sitemap.create do
          Rails.logger.debug "Starting sitemap creation"

          # Main pages (sitemap_generator automatically adds the root URL)
          add "/experiences", changefreq: "daily", priority: 0.9
          add "/search", changefreq: "weekly", priority: 0.7
          add "/terms", changefreq: "monthly", priority: 0.5
          add "/privacy", changefreq: "monthly", priority: 0.5

          # Add approved experiences dynamically
          experience_count = 0
          Experience.approved.find_each do |experience|
            raise "Experience ID is nil" if experience.id.nil?

            add "/experiences/#{experience.id}/display",
                lastmod: experience.updated_at,
                changefreq: "weekly",
                priority: 0.6
            experience_count += 1
          end

          Rails.logger.debug "Added #{experience_count} experiences to sitemap"
        end

        # Get the sitemap content from memory
        # Debug what files were actually created
        Rails.logger.debug "Available files in adapter: #{adapter.data.keys.inspect}"

        raise "No files were created by SitemapGenerator" if adapter.data.empty?

        # Try both compressed and uncompressed filenames
        sitemap_data = adapter.data["sitemap.xml"] || adapter.data["sitemap.xml.gz"]

        if sitemap_data.nil?
          available_files = adapter.data.keys.join(", ")
          raise "Sitemap file not found. Available files: #{available_files}"
        end

        content = sitemap_data.string
        raise "Sitemap content is empty" if content.blank?

        Rails.logger.info "Successfully generated sitemap content (#{content.length} bytes)"
        content
      end
     rescue StandardError => e
      Rails.logger.error "Error in generate_dynamic_sitemap: #{e.class.name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
     ensure
      Rails.logger.debug "Restoring original SitemapGenerator configuration"
      # Restore original configuration
      SitemapGenerator::Sitemap.default_host = original_host
      SitemapGenerator::Sitemap.adapter = original_adapter
      SitemapGenerator::Sitemap.compress = original_compress
     end
   end
end
