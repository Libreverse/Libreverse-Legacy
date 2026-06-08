require "json"
require "minify_html"
require "digest/sha1"
require "nokogiri"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # NOTE: We don't pre-split or exclude tags like <pre>, <textarea>, or <script>.
    # minify_html is spec-aware and preserves content of rawtext/RCDATA elements safely,
    # so an explicit "preserve" regex is unnecessary and can introduce edge-case bugs.
  end

  DISPLAY_PAGE_PATH = %r{\A/experiences/[^/]+/display(?:\.[^/]+)?\z}.freeze

  def call(env)
    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless headers["Content-Type"]&.include?("text/html")
    return [ status, headers, body ] if display_page?(env)

    Rails.logger.debug "WhitespaceCompressor: Processing HTML response" if defined?(Rails)

    # Step 1: Assemble HTML efficiently
    return [ status, headers, body ] unless body.respond_to?(:each)

    chunks = []
    body.each { |chunk| chunks << chunk.to_s.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join
    # We replace the body, so close the original to avoid leaks
    body.close if body.respond_to?(:close)

    Rails.logger.debug "WhitespaceCompressor: Original HTML length: #{html.length}" if defined?(Rails)

    # Caching: Use Rails.cache to store processed HTML based on SHA1 hash of original
    # This saves unnecessary work for repeated identical responses (e.g., static pages)
    unless html.empty?
      cache_key = "wc_html:#{::Digest::SHA1.hexdigest(html)}"
      html = (defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : nil)&.fetch(cache_key, expires_in: 1.hour) do
        # Step 1.5: Minify JSON-LD scripts before other processing (Nokogiri-based)
        processed = minify_jsonld_scripts_with_nokogiri(html)

        # Step 1.6: Minify iframe srcdoc content (Nokogiri-based)
        processed = minify_srcdoc_iframes_with_nokogiri(processed)

        # Step 2: Apply minify_html for efficient whitespace and comment removal
        # Configure minify_html options for optimal minification
        minify_config = {
          allow_noncompliant_unquoted_attribute_values: true, # Safe for modern browsers
          allow_optimal_entities: true,                        # Safe optimizations
          allow_removing_spaces_between_attributes: true,      # Safe space removal
          keep_closing_tags: false,                            # Omit unnecessary closing tags
          keep_comments: false,                                # Remove all comments
          keep_html_and_head_opening_tags: false,              # Omit if no attributes
          keep_input_type_text_attr: false,                    # Omit default type=text
          keep_ssi_comments: false,                            # Remove SSI comments
          minify_css: false,                                   # Skip since already minified
          minify_doctype: true,                                # Minify DOCTYPE
          minify_js: false,                                    # Skip since already minified
          preserve_brace_template_syntax: false,               # Don't preserve unless using {{ }} templates
          preserve_chevron_percent_template_syntax: false,     # Don't preserve unless using <% %> templates
          remove_bangs: true,                                  # Remove bangs
          remove_processing_instructions: true                 # Remove processing instructions
        }

        # Always apply minify_html for optimal compression - it's more effective than HAML's whitespace removal
        safe_minify_html(processed, minify_config)
      end || begin
        # Fallback path when Rails.cache is unavailable
        processed = minify_jsonld_scripts_with_nokogiri(html)
        processed = minify_srcdoc_iframes_with_nokogiri(processed)
        safe_minify_html(processed, {
                           allow_noncompliant_unquoted_attribute_values: true,
                           allow_optimal_entities: true,
                           allow_removing_spaces_between_attributes: true,
                           keep_closing_tags: false,
                           keep_comments: false,
                           keep_html_and_head_opening_tags: false,
                           keep_input_type_text_attr: false,
                           keep_ssi_comments: false,
                           minify_css: false,
                           minify_doctype: true,
                           minify_js: false,
                           preserve_brace_template_syntax: false,
                           preserve_chevron_percent_template_syntax: false,
                           remove_bangs: true,
                           remove_processing_instructions: true
                         })
      end
    end

    Rails.logger.debug "WhitespaceCompressor: Minified HTML length: #{html.length}" if defined?(Rails)

    # Update headers before returning
    new_headers = headers.dup
    new_headers["Content-Length"] = html.bytesize.to_s
    new_headers.delete("Content-Encoding")
    [ status, new_headers, [ html ] ]
  end

  # Minify JSON-LD scripts by parsing and re-serializing JSON content (no regex lookaheads/backrefs)
  def minify_jsonld_scripts_with_nokogiri(html)
    doc = Nokogiri::HTML4.parse(html)
    doc.css("script").each do |node|
      type = node["type"]
      next unless type && type.to_s.downcase.strip == "application/ld+json"

      raw = node.children.to_s
      # Strip CDATA if present
      cleaned = raw.sub(/^\s*<!\[CDATA\[/, "").sub(/\]\]>\s*$/, "").strip
      next unless cleaned.start_with?("{", "[")

      begin
        minified = JSON.generate(JSON.parse(cleaned))
        node.children = Nokogiri::XML::Text.new(minified, doc)
      rescue JSON::ParserError
        # ignore invalid JSON
      end
    end
    doc.to_html
  rescue StandardError => e
    Rails.logger.warn "WhitespaceCompressor: Failed JSON-LD minify: #{e.class}: #{e.message}" if defined?(Rails)
    html
  end

  # Minify inline HTML in iframe[srcdoc] attributes using Nokogiri
  def minify_srcdoc_iframes_with_nokogiri(html)
    doc = Nokogiri::HTML4.parse(html)
    doc.css("iframe[srcdoc]").each do |node|
      content = node["srcdoc"].to_s
      next if content.strip.empty?
      next unless content.lstrip.start_with?("<")

      begin
        minified_content = safe_minify_html(content, {
                                              allow_noncompliant_unquoted_attribute_values: true,
                                              allow_optimal_entities: true,
                                              allow_removing_spaces_between_attributes: true,
                                              keep_closing_tags: false,
                                              keep_comments: false,
                                              keep_html_and_head_opening_tags: false,
                                              keep_input_type_text_attr: false,
                                              keep_ssi_comments: false,
                                              minify_css: true,
                                              minify_doctype: true,
                                              minify_js: false,
                                              preserve_brace_template_syntax: false,
                                              preserve_chevron_percent_template_syntax: false,
                                              remove_bangs: true,
                                              remove_processing_instructions: true
                                            })
        node["srcdoc"] = minified_content
      rescue StandardError => e
        Rails.logger.warn "WhitespaceCompressor: Failed to minify srcdoc: #{e.message}" if defined?(Rails)
      end
    end
    doc.to_html
  rescue StandardError => e
    Rails.logger.warn "WhitespaceCompressor: Failed srcdoc pass: #{e.class}: #{e.message}" if defined?(Rails)
    html
  end

  def safe_minify_html(html, config)
    minify_html(html, config)
  rescue StandardError => e
    Rails.logger.warn "WhitespaceCompressor: Failed HTML minify: #{e.class}: #{e.message}" if defined?(Rails)
    html
  end

  def display_page?(env)
    env["PATH_INFO"].to_s.match?(DISPLAY_PAGE_PATH)
  end
end
