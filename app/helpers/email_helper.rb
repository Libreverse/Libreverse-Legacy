module EmailHelper
  # Main email CSS inlining method that works in all environments
  def inline_email_css(css_entry = "~/stylesheets/emails.scss")
    case Rails.env.to_sym
    when :development
      development_email_css(css_entry)
    when :production
      production_email_css(css_entry)
    when :test
      test_email_css(css_entry)
    end
  end

  # Public method for directly inlining a specific Vite stylesheet
  # This provides a simple interface for mailers to inline CSS without going through
  # the full email CSS processing pipeline
  def inline_vite_stylesheet(stylesheet_path)
    if Rails.env.development?
      # Use the ViteCssFetcher service for development
      ViteCssFetcher.fetch_css(stylesheet_path)
    else
      # In production, use compiled assets
      asset_path = ActionController::Base.helpers.asset_path(stylesheet_path)
      css_file_path = Rails.root.join("public", asset_path.sub(%r{^/}, ""))

      if File.exist?(css_file_path)
        File.read(css_file_path)
      else
        Rails.logger.warn "CSS file not found: #{css_file_path}"
        ""
      end
    end
  end

  # Default CSS for mailer layout when no specific CSS is provided
  def default_email_css
    inline_email_css("~/stylesheets/emails.scss")
  rescue StandardError => e
    Rails.logger.warn "[EmailHelper] Error loading default email CSS: #{e.message}"
    # Fallback to basic Foundation for Emails CSS
    foundation_email_css_fallback
  end

  # Apply emoji SVG replacement to entire HTML content for email compatibility
  def process_email_content(content)
    # Use the existing fast emoji renderer to replace all emojis with inline SVGs
    # rubocop:disable Rails/OutputSafety
    Emoji::Renderer.replace(content.to_s).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private

  # Development: Fetch CSS from Vite dev server using ViteCssFetcher service
  def development_email_css(css_entry)
      # Use the ViteCssFetcher service for development
      css_content = ViteCssFetcher.fetch_css(css_entry)
      return inline_css_content(css_content) if css_content.present?

      # Fallback to Foundation for Emails CDN if no CSS found
      foundation_email_css_fallback
  rescue StandardError => e
      Rails.logger.warn "[EmailHelper] Error fetching development CSS: #{e.message}"
      foundation_email_css_fallback
  end

  # Production: Extract CSS from Vite manifests and inline
  def production_email_css(css_entry)
      # Try to get CSS from the emails.scss entry point
      if css_entry.include?("emails")
        css_content = email_css_from_manifest
        return inline_css_content(css_content) if css_content.present?
      end

      # Try to extract CSS from JavaScript bundle
      js_entry = css_entry.sub(/\.scss$/, ".js").sub(/stylesheets/, "javascript")
      css_content = extract_css_from_js_bundle(js_entry)
      return inline_css_content(css_content) if css_content.present?

      # Fallback to direct CSS file
      css_content = get_css_directly_from_manifest(css_entry)
      return inline_css_content(css_content) if css_content.present?

      # Final fallback: try to read CSS file directly from public directory
      css_file_path = Rails.root.join("public", "assets", css_entry.sub(%r{^~/}, "").sub(/\.scss$/, ".css"))
      if File.exist?(css_file_path)
        css_content = File.read(css_file_path)
        return inline_css_content(css_content) if css_content.present?
      end

      Rails.logger.warn "[EmailHelper] No CSS found for #{css_entry} in production"
      ""
  rescue StandardError => e
      Rails.logger.error "[EmailHelper] Error in production CSS inlining: #{e.message}"
      ""
  end

  # Test: Use simple CSS inclusion for faster tests
  def test_email_css(_css_entry)
    # In test environment, use minimal CSS for speed
    basic_email_css = <<~CSS
      body { font-family: Arial, sans-serif; line-height: 1.6; }
      .container { max-width: 600px; margin: 0 auto; }
      .button { background: #007cba; color: white; padding: 10px 20px; text-decoration: none; }
    CSS
    inline_css_content(basic_email_css)
  end

  # Fetch CSS from Vite development server
  def fetch_css_from_dev_server(css_url)
    response = HTTParty.get(css_url,
                            timeout: 5,
                            open_timeout: 5,
                            headers: {
                              "Accept" => "text/css"
                            })

    return response.body if response.code == 200

    Rails.logger.warn "[EmailHelper] Failed to fetch CSS from dev server: #{response.code}"
    nil
  rescue StandardError => e
    Rails.logger.warn "[EmailHelper] Dev server request failed: #{e.message}"
    nil
  end

  # Get CSS from the dedicated emails build
  def email_css_from_manifest
    return nil unless ViteRuby.instance.manifest

    # Look for the emails entry in the manifest
    emails_entry = ViteRuby.instance.manifest.resolve_entries("stylesheets/emails.scss")
    css_files = emails_entry[:stylesheets] || []

    return nil if css_files.empty?

    # Read the first CSS file (or combine multiple if needed)
    css_file_path = css_files.first
    full_path = Rails.root.join("public", ViteRuby.config.public_output_dir, css_file_path)

    File.exist?(full_path) ? File.read(full_path) : nil
  rescue StandardError => e
    Rails.logger.warn "[EmailHelper] Error reading emails CSS from manifest: #{e.message}"
    nil
  end

  # Extract CSS that might be bundled within JavaScript
  def extract_css_from_js_bundle(js_entry)
    manifest_key = js_entry.sub(%r{^~/}, "")

    # Try using the existing helper method
    if respond_to?(:get_vite_asset_content)
      js_content = get_vite_asset_content(manifest_key, type: :javascript)
      return extract_css_from_js_content(js_content) if js_content.present?
    end

    # Fallback to direct manifest lookup
    js_path = ViteRuby.instance.manifest.path_for(manifest_key, type: :javascript)
    return nil unless js_path

    full_js_path = Rails.root.join("public", ViteRuby.config.public_output_dir, js_path)
    return nil unless File.exist?(full_js_path)

    js_content = File.read(full_js_path)
    extract_css_from_js_content(js_content)
  rescue StandardError => e
    Rails.logger.warn "[EmailHelper] Error extracting CSS from JS bundle: #{e.message}"
    nil
  end

  # Extract CSS content from JavaScript string
  def extract_css_from_js_content(js_content)
    # Look for CSS strings in the JavaScript (common Vite pattern)
    css_matches = js_content.scan(/(?:createStyle|insertStyle|injectCSS)\(['"`]([^'"`]+)['"`]\)/)
    return css_matches.map(&:first).join("\n") if css_matches.any?

    # Look for style injection patterns
    style_matches = js_content.scan(/\.textContent\s*=\s*['"`]([^'"`]+)['"`]/)
    return style_matches.map(&:first).join("\n") if style_matches.any?

    # Look for CSS template literals
    template_matches = js_content.scan(/`([^`]*(?:body|\.[\w-]+|#[\w-]+)[^`]*)`/)
    css_like = template_matches.select { |match| match.first.include?("{") && match.first.include?("}") }
    return css_like.map(&:first).join("\n") if css_like.any?

    nil
  end

  # Get CSS directly from manifest (for separate CSS builds)
  def get_css_directly_from_manifest(css_entry)
    manifest_key = css_entry.sub(%r{^~/}, "").sub(/\.scss$/, ".css")
    css_path = ViteRuby.instance.manifest.path_for(manifest_key, type: :stylesheet)
    return nil unless css_path

    full_path = Rails.root.join("public", ViteRuby.config.public_output_dir, css_path)
    File.exist?(full_path) ? File.read(full_path) : nil
  rescue StandardError => e
    Rails.logger.warn "[EmailHelper] Error getting CSS directly from manifest: #{e.message}"
    nil
  end

  # Wrap CSS content in style tags with proper attributes
  def inline_css_content(css_content)
    return "" if css_content.blank?

    # Clean up the CSS content (comments via non-backtracking scan; CSS is local/build assets)
    strip_css_comments(css_content.to_s)
      .strip
      .gsub(/\s+/, " ") # Compress whitespace
      .gsub(/;\s*}/, "}") # Clean up semicolons

    # Return just the cleaned CSS content (not wrapped in tags)
  end

  # Linear-time CSS comment stripper (avoids polynomial ReDoS on nested comment-like input).
  def strip_css_comments(css)
    out = +""
    i = 0
    len = css.length
    while i < len
      if css[i, 2] == "/*"
        close = css.index("*/", i + 2)
        i = close ? close + 2 : len
      else
        out << css[i]
        i += 1
      end
    end
    out
  end

  # Fallback CSS using Foundation for Emails from CDN
  def foundation_email_css_fallback
    Rails.logger.info "[EmailHelper] Using Foundation for Emails CDN fallback"

    # Provide a minimal inline Foundation-like CSS
    fallback_css = <<~CSS
      /* Foundation for Emails Fallback */
      body { margin: 0; padding: 0; font-family: Arial, sans-serif; line-height: 1.6; }
      table { border-spacing: 0; border-collapse: collapse; }
      td { vertical-align: top; }
      .container { width: 100%; max-width: 600px; margin: 0 auto; }
      .row { width: 100%; }
      .columns { padding-left: 8px; padding-right: 8px; }
      .button { background: #2199e8; border: none; color: white; padding: 8px 16px; text-decoration: none; display: inline-block; }
      .text-center { text-align: center; }
      .float-center { margin: 0 auto; float: none; text-align: center; }
    CSS

    inline_css_content(fallback_css)
  end
end
