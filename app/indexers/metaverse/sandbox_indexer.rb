require "cgi"

module Metaverse
  # Indexer for The Sandbox metaverse content
  # Parses the sitemap at https://www.sandbox.game/__sitemap__/experiences.xml
  # NOTE: Currently blocked by Cloudflare bot protection - keep disabled until resolved
  class SandboxIndexer < BaseIndexer
    include RateLimitable
    include Cacheable
    include ErrorHandler
    include ProgressTrackable

    SITEMAP_URL = "https://www.sandbox.game/__sitemap__/experiences.xml".freeze
    FALLBACK_MAIN_SITEMAP = "https://www.sandbox.game/sitemap.xml".freeze

    def platform_name
      "sandbox"
    end

    def fetch_items
      log_info "Starting Sandbox experience indexing"
      log_info "Target: #{SITEMAP_URL}"

      experiences =
        begin
          fetch_experiences_via_browser
        rescue CloudflareBlockError => e
          log_error "Cloudflare protection blocking access: #{e.message}"
          # Try fallback method or return empty array
          log_info "Attempting fallback via main sitemap..."
          fetch_experiences_fallback
        rescue BotProtectionError => e
          log_error "Bot protection blocking access: #{e.message}"
          []
        rescue StandardError => e
          log_error "Error fetching Sandbox experiences: #{e.message}"
          raise
        end

      log_info "Successfully fetched #{experiences.count} Sandbox experiences"
      experiences
    end

    def process_item(experience_data)
      log_debug "Processing experience: #{experience_data[:title]} (#{experience_data[:uuid]})"

      normalized_data = normalize_content(experience_data)

      # Save the indexed content
      indexed_content = save_indexed_content(normalized_data)

      if indexed_content
        log_debug "Successfully processed experience: #{experience_data[:title]}"
        update_progress(1)
      else
        handle_item_error(StandardError.new("Failed to save indexed content"), experience_data)
      end

      indexed_content
    end

    protected

    def normalize_content(experience_data)
      {
        source_platform: platform_name,
        external_id: experience_data[:uuid],
        content_type: "experience",
        title: clean_title(experience_data[:title]),
        description: nil, # Not available in sitemap
        author: nil, # Not available in sitemap
        coordinates: nil, # Sandbox doesn't use coordinate system like Decentraland
        metadata: {
          source_url: experience_data[:url],
          sitemap_row: experience_data[:row_index],
          original_title: experience_data[:title],
          indexed_at: Time.current.iso8601
        }
      }
    end

    def extract_external_id(raw_data)
      raw_data[:uuid]
    end

    def extract_content_type(_raw_data)
      "experience"
    end

    def extract_title(raw_data)
      clean_title(raw_data[:title])
    end

    def extract_description(_raw_data)
      nil # Not available in sitemap
    end

    def extract_author(_raw_data)
      nil # Not available in sitemap
    end

    def extract_coordinates(_raw_data)
      nil # Sandbox doesn't use coordinate system
    end

    def extract_metadata(raw_data)
      {
        source_url: raw_data[:url],
        sitemap_row: raw_data[:row_index],
        original_title: raw_data[:title],
        indexed_at: Time.current.iso8601
      }
    end

    private

    def fetch_experiences_via_browser
      log_info "Using headless browser to fetch sitemap"

      begin
        # Use the base class make_request method which handles browser setup
        response = make_request(SITEMAP_URL)

        # Parse the HTML response
        html_content = response.parsed_response
        parse_sitemap_html(html_content)
      rescue CloudflareBlockError, BotProtectionError
        raise # Re-raise these specific errors
      rescue StandardError => e
        log_error "Browser request failed: #{e.message}"
        raise
      end
    end

    def fetch_experiences_fallback
      log_info "Attempting fallback via main sitemap"

      begin
        response = make_request(FALLBACK_MAIN_SITEMAP)
        html_content = response.parsed_response

        # Try to find experience links in the main sitemap
        parse_sitemap_html(html_content)
      rescue StandardError => e
        log_warn "Fallback also failed: #{e.message}"
        []
      end
    end

    def parse_sitemap_html(html_content)
      log_debug "Parsing sitemap content"
      doc = Nokogiri::HTML(html_content)

      # Check if this is XML sitemap format
      experiences = if html_content.include?("<?xml") || html_content.include?("<urlset")
        parse_xml_sitemap(html_content)
      else
        # Parse HTML table format
        parse_html_sitemap(doc)
      end

      log_debug "Parsed #{experiences.count} experiences"
      experiences
    end

    def parse_xml_sitemap(html_content)
      log_debug "Parsing XML sitemap format"

      experiences = []
      xml_doc = Nokogiri::XML(html_content)

      # Look for URL entries
      url_entries = xml_doc.css("url")

      index = 0
      while index < url_entries.length
        entry = url_entries[index]
        loc = entry.at_css("loc")&.text

        unless loc&.include?("/experiences/")
          index += 1
          next
        end

        unless (match = loc.match(%r{/experiences/([^/]+)/([a-f0-9-]{36})/page}))
          index += 1
          next
        end

        title_encoded = match[1]
        uuid = match[2]

        title = decode_title(title_encoded)

        experiences << {
          title: title,
          uuid: uuid,
          url: loc,
          row_index: index + 1
        }

        index += 1
      end

      experiences
    end

    def parse_html_sitemap(doc)
      log_debug "Parsing HTML table sitemap format"

      experiences = []

      # Look for the sitemap table
      table = doc.at_css("table#sitemap")
      return experiences unless table

      # Get all table rows (skip header)
      rows = table.css("tbody tr")

      index = 0
      while index < rows.length
        row = rows[index]
        # Get the first cell which contains the experience URL
        url_cell = row.at_css("td:first-child a")

        unless url_cell
          index += 1
          next
        end

        href = url_cell["href"]
        unless href&.include?("/experiences/")
          index += 1
          next
        end

        # Extract title and UUID from URL
        unless (match = href.match(%r{/experiences/([^/]+)/([a-f0-9-]{36})/page}))
          index += 1
          next
        end

        title_encoded = match[1]
        uuid = match[2]

        title = decode_title(title_encoded)

        experiences << {
          title: title,
          uuid: uuid,
          url: href,
          row_index: index + 1
        }

        index += 1
      end

      experiences
    end

    def decode_title(title_encoded)
      # Decode URL encoding
      title = CGI.unescape(title_encoded)

      # Handle various encoding scenarios
      title = title.gsub("%20", " ").tr("+", " ")

      # Additional cleanup for common patterns
      title = title.gsub("%2C", ",")
                   .gsub("%21", "!")
                   .gsub("%3A", ":")
                   .gsub("%28", "(")
                   .gsub("%29", ")")

      title.strip
    end

    def clean_title(title)
      return "" if title.blank?

      # Remove any remaining URL encoding artifacts
      cleaned = title.gsub(/(%[0-9A-Fa-f]{2})/, " ")
                     .gsub(/\s+/, " ")
                     .strip

      # Ensure it's not too long for database
      cleaned.truncate(255)
    end

    # Handle sync logic - keep experiences in sync with sitemap
    def sync_experiences(current_experiences)
      log_info "Syncing Sandbox experiences with sitemap"

      current_uuids = current_experiences.map { |exp| exp[:uuid] }.to_set

      # Find existing indexed content for this platform
      existing_content = IndexedContent.where(source_platform: platform_name)
      existing_uuids = existing_content.pluck(:external_id).to_set

      # Find experiences to remove (no longer in sitemap)
      to_remove = existing_uuids - current_uuids

      if to_remove.any?
        log_info "Removing #{to_remove.count} experiences no longer in sitemap"
        IndexedContent.where(source_platform: platform_name, external_id: to_remove.to_a).destroy_all
      end

      # New experiences will be handled by the normal processing flow
      new_experiences = current_uuids - existing_uuids
      log_info "Found #{new_experiences.count} new experiences to index"

      {
        total_current: current_experiences.count,
        existing: existing_uuids.count,
        new: new_experiences.count,
        removed: to_remove.count
      }
    end

    # Override the main index! method to add sync logic
    def index!(options = {})
      start_indexing_run(options)

      log_info "Starting Sandbox indexing with sync"

      begin
        items = with_retry { fetch_items }
        total_items(items.size)
        log_info "Found #{items.size} items to process"

        # Perform sync before processing
        sync_stats = sync_experiences(items)
        log_info "Sync complete: #{sync_stats}"

        # Process items in batches
        process_items_in_batches(items)

        complete_indexing_run
        log_progress_summary
        log_info "Sandbox indexing completed successfully"
      rescue StandardError => e
        fail_indexing_run(e)
        log_error "Sandbox indexing failed: #{e.message}"
        raise
      end
    end
  end

  # Custom error for Cloudflare blocking
  class CloudflareBlockError < StandardError; end
end
