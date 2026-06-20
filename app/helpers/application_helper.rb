module ApplicationHelper
  include BetterHtml::Helpers
  include EmojiHelper # Include the new helper
  include EmailHelper # Include email CSS inlining helper
  include ExperiencePlatformHelper
  require "base64"
  require "unicode"
  require "cgi"
  require "uri"

  # Ensure subsequent original methods are public

  def auth_page?
    auth_paths = %w[/login /create-account /change-password /multi-phase-login]
    auth_paths.any? { |path| request.path.include?(path) }
  end

  def page_with_drawer?
    content_for?(:drawer)
  end

  def seo_config(key)
    # Use the Rails config store instead of the old constant
    Rails.application.config.x.seo_config[key.to_s]
  end

  def sidebar_icon(path, additional_class = "")
    image_tag(path,
              class: "sidebar-icons #{additional_class}".strip,
              loading: "eager",
              decoding: "async",
              fetchpriority: "high",
              draggable: "false",
              aria: { hidden: true },
              tabindex: "-1")
  end

  # Returns the flag emoji for a given locale symbol.
  # Example: :en => 🇺🇸
  def locale_flag_emoji(locale)
    {
      en: "🇺🇸",
      zh: "🇨🇳",
      es: "🇪🇸",
      hi: "🇮🇳",
      ar: "🇸🇦",
      pt: "🇧🇷",
      fr: "🇫🇷",
      ru: "🇷🇺",
      de: "🇩🇪",
      ja: "🇯🇵"
    }[locale.to_sym] || "🏳️"
  end

  # --- SEO Asset Path Helpers (Moved from initializer) ---

  # Resolves SEO-specific asset paths (e.g., with @ or ~/ prefixes)
  # Note: Assumes vite_asset_path is available in this helper context.
  def seo_asset_path(path)
    if path.is_a?(String)
      if path.start_with?("@")
        # For @ prefixed assets, look in images directory (not static)
        vite_asset_path("images/#{path.sub('@', '')}")
      elsif path.start_with?("~/static/")
        # For explicit static asset references
        vite_asset_path(path)
      elsif path.start_with?("~/")
        # For other ~/ prefixed assets, use as-is with vite_asset_path
        vite_asset_path(path)
      else
        # Return unchanged for other paths
        path
      end
    else
      # Return unchanged for non-string values
      path
    end
  end

  # Convenience method to get SEO config value, resolving asset paths where needed.
  # Accesses the configuration stored in Rails.application.config.x.seo_config
  def seo_config_with_assets(key)
    value = Rails.application.config.x.seo_config[key.to_s]

    # Special handling for asset keys that need path resolution
    if %w[preview_image shortcut_icon apple_touch_icon mask_icon].include?(key.to_s)
      seo_asset_path(value)
    else
      value
    end
  end

  # --- End SEO Asset Path Helpers ---

  # --- Request/Context Helpers for Asset Inlining Optimizations ---
  # Detect Turbo visit/frame requests so we can skip inlining on Turbo navigations
  def turbo_request?
    request.headers["X-Turbo-Request-Id"].present?
  end

  # True if the HTTP Referer is from the same site (host and port match)
  # Treats a missing/blank referrer as external (returns false)
  def same_site_referrer?
    ref = request.referer
    return false if ref.blank?

    begin
      uri = URI.parse(ref)
      ref_host = uri.host
      ref_scheme = uri.scheme
      ref_port = uri.port || (ref_scheme == "https" ? 443 : 80)
      ref_host == request.host && ref_port == request.port
    rescue URI::InvalidURIError
      false
    end
  end

  # We inline assets only when:
  # - production environment
  # - NOT a Turbo request (full document load only)
  # - referrer is not same-site (including when blank)
  def should_inline_assets?
    Rails.env.production? && !turbo_request? && !same_site_referrer?
  end
  # --- End Request/Context Helpers ---

  # --- Vite Asset Inlining Helpers ---
  # Emit a <link rel="modulepreload"> for a Vite JS entry; useful when we inline JS but still want the browser to fetch/cache the file
  def vite_modulepreload_link(entry_path)
    href = vite_asset_path(entry_path)
    # rel=modulepreload should also set as=script and crossorigin for proper semantics
    tag.link(rel: "modulepreload", href: href, as: "script", crossorigin: "")
  end

  # Generate <link rel="stylesheet"> tags for the CSS extracted from a given JS entry
  # Uses the Vite manifest to find associated stylesheets.
  def vite_stylesheet_links_for_entry(name_with_prefix, **options)
    if Rails.env.development? || Rails.env.test?
      # In dev/test we rely on the JS entry importing the SCSS; no separate tags required.
      return ""
    end

    manifest_key = name_with_prefix.sub(%r{^~/}, "")
    css_paths = Array(ViteRuby.instance.manifest.resolve_entries(manifest_key)[:stylesheets])
    return "" if css_paths.empty?

    public_dir = ViteRuby.instance.config.public_output_dir
    links = css_paths.map do |css_path|
      # css_path may include the public dir; normalize to "/<public_dir>/<rel_path>"
      rel_path = css_path.sub(%r{^/?#{Regexp.escape(public_dir)}/}, "")
      href = File.join("/", public_dir, rel_path)
      tag.link({ rel: "stylesheet", href: href }.merge(options))
    end
    safe_join(links)
  end

  # Email-specific helper to inline Foundation for Emails styles
  def inline_email_styles
    inline_vite_stylesheet("~/emails.css")
  end

  # Guard patterns to safely inline assets without prematurely closing their tags
  SCRIPT_CLOSE_REGEX = %r{</script\b}i
  STYLE_CLOSE_REGEX  = %r{</style\b}i

  def inline_vite_stylesheet(name_with_prefix, **options)
    unless Rails.env.production?
      # Development / Test – request the CSS build that Vite serves for the same entrypoint
      css_entry = name_with_prefix.sub(/\.js\z/, ".css")
      return vite_stylesheet_tag(css_entry, **options)
    end

    # Production – inline the compiled CSS to avoid extra requests.
    manifest_key = name_with_prefix.sub(%r{^~/}, "")

    # Vite lists all CSS generated for an entrypoint under `css` in the manifest.
    css_paths = Array(ViteRuby.instance.manifest.resolve_entries(manifest_key)[:stylesheets])
    return if css_paths.empty?

    # Currently we inline the *first* stylesheet; if you code-split CSS you may
    # need a loop or merge – adjust as needed.
    css_rel_path = css_paths.first.sub(%r{^/?#{Regexp.escape(ViteRuby.instance.config.public_output_dir)}/}, "")
    file_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, css_rel_path)

    unless File.exist?(file_path)
      Rails.logger.error "[ViteInline] Stylesheet not found at #{file_path} (entry: #{manifest_key})"
      return
    end

    # Read from disk with cache; invalidate when manifest changes
    raw_css = Rails.cache.fetch([
      :vite_inline,
      :css,
      vite_manifest_version,
      css_rel_path
    ].join(":"), expires_in: 24.hours) do
      File.read(file_path)
    end

    # Escape any `</style>` (or variants) that would prematurely close the tag
    safe_css = raw_css.gsub(STYLE_CLOSE_REGEX, '<\\/style>')

    nonce_opt   = { nonce: content_security_policy_nonce }
    merged_opts = options.merge(nonce_opt) { |_k, old, new| old || new }

    # Sanitize CSS content before marking as safe
    sanitized_css = ActionController::Base.helpers.sanitize(safe_css, tags: [])

    # rubocop:disable Rails/OutputSafety
    tag.style(sanitized_css.html_safe, **merged_opts)
    # rubocop:enable Rails/OutputSafety
  end

  def inline_vite_javascript(name_with_prefix, **options)
    if Rails.env.development? || Rails.env.test?
        # In development and test, keep the standard Vite tag so the dev server
        # (and HMR) handles JavaScript resources.
        vite_javascript_tag(name_with_prefix, **options)
    else
        # In production, inline the content directly
        manifest_key = name_with_prefix.sub(%r{^~/}, "")
        content = get_vite_asset_content(manifest_key, type: :javascript)
        if content
        # JS is generated by Vite; mark as safe for direct embedding.
        # Attach the current request's CSP nonce so that inline scripts are allowed
        nonce_opt = { nonce: content_security_policy_nonce }
        safe_content = content.gsub(SCRIPT_CLOSE_REGEX, '<\\/script>')

        # Remove the sanitization step that's converting & to &amp;, < to &lt;, etc.
        # The content from Vite is already safe JavaScript code

        merged_opts = { type: "module" }.merge(options).merge(nonce_opt) { |_k, old, new| old || new }
        # rubocop:disable Rails/OutputSafety
        tag.script(safe_content.html_safe, **merged_opts)
          # rubocop:enable Rails/OutputSafety
        end
    end
  end

  # Inline font helper: Generates a style tag with an embedded @font-face rule.
  # Example usage: inline_vite_font('~/fonts/myfont.woff2', font_family: 'MyFont')
  def inline_vite_font(font_path, **options)
    manifest_key = font_path.sub(%r{^~/}, "")
    content = get_vite_asset_content(manifest_key, type: :font)
    return if content.blank?

    ext = File.extname(manifest_key).downcase
    mime = case ext
    when ".woff2" then "font/woff2"
    when ".woff" then "font/woff"
    when ".ttf"   then "font/ttf"
    when ".otf"   then "font/otf"
    else "application/octet-stream"
    end

    base64_content = Base64.strict_encode64(content)
    data_uri = "data:#{mime};base64,#{base64_content}"

    font_family = options.delete(:font_family) || File.basename(manifest_key, ext)
    css = <<~CSS
      @font-face {
        font-family: '#{font_family}';
        src: url("#{data_uri}") format("#{ext.delete('.')}");
        font-weight: normal;
        font-style: normal;
      }
    CSS

    nonce_opt = Rails.env.production? ? { nonce: content_security_policy_nonce } : {}
    # rubocop:disable Rails/OutputSafety
    tag.style(css.html_safe, **nonce_opt.merge(options))
    # rubocop:enable Rails/OutputSafety
  end

  # Validate icon name to prevent path traversal
  def svg_icon_content(icon_name)
    unless icon_name.match?(/\A[a-zA-Z0-9_-]+\z/)
      Rails.logger.warn "Invalid SVG icon name requested: #{icon_name}"
      return ""
    end

    # Define potential directories and find the icon
    potential_dirs = [ Rails.root.join("app/icons"), Rails.root.join("app/images") ]
    icon_path = nil
    potential_dirs.each do |dir|
      path = dir.join("#{icon_name}.svg")
      Rails.logger.info "Checking for SVG at: #{path}"
      next unless path.to_s.start_with?(dir.to_s) && File.exist?(path) && File.file?(path)

      icon_path = path
      Rails.logger.info "Found SVG at: #{icon_path}"
      break
    end

    unless icon_path
      Rails.logger.warn "SVG icon not found in checked directories: #{icon_name}"
      return ""
    end

    # Read and validate SVG content (cache by file version)
    svg_content = Rails.cache.fetch([
      :svg_icon_content,
      icon_path.to_s,
      file_version(icon_path)
    ].join(":"), expires_in: 24.hours) { File.read(icon_path) }
    Rails.logger.info "Read SVG content for #{icon_name}: #{svg_content.length} characters, preview: #{svg_content[0..100]}"

    # Basic SVG validation
    unless svg_content.include?("<svg") && svg_content.include?("</svg>")
      Rails.logger.warn "Invalid SVG content detected for icon: #{icon_name}"
      return ""
    end

    # Return raw SVG content (not data URL encoded)
    svg_content.strip
  end

  def svg_icon_data_url(icon_name)
    # Validate icon name to prevent path traversal
    unless icon_name.match?(/\A[a-zA-Z0-9_-]+\z/)
      Rails.logger.warn "Invalid SVG icon name requested: #{icon_name}"
      return ""
    end

    # Define potential directories and find the icon
    potential_dirs = [ Rails.root.join("app/icons"), Rails.root.join("app/images") ]
    icon_path = nil
    potential_dirs.each do |dir|
      path = dir.join("#{icon_name}.svg")
      if path.to_s.start_with?(dir.to_s) && File.exist?(path) && File.file?(path)
        icon_path = path
        break
      end
    end

    unless icon_path
      Rails.logger.warn "SVG icon not found in checked directories: #{icon_name}"
      return ""
    end

    # Read and validate SVG content (cache by file version)
    svg_content = Rails.cache.fetch([
      :svg_icon_data_url,
      icon_path.to_s,
      file_version(icon_path)
    ].join(":"), expires_in: 24.hours) { File.read(icon_path) }

    # Basic SVG validation
    unless svg_content.include?("<svg") && svg_content.include?("</svg>")
      Rails.logger.warn "Invalid SVG content detected for icon: #{icon_name}"
      return ""
    end

    # Encode the SVG for a data URL using URL encoding instead of base64
    # Use ERB::Util.url_encode for proper SVG data URL encoding
    "data:image/svg+xml,#{ERB::Util.url_encode(svg_content)}"
  end

  # Generates Base64-encoded data URIs for all available bitmap image versions.
  # Looks for the image in the source asset directories (e.g., app/images)
  # and returns a hash of all found versions (AVIF, WebP, PNG, JPG, GIF) for the given base image path.
  #
  # @param source_relative_path [String] The path relative to the asset source root (e.g., "images/logo").
  # @return [Hash{String=>String}] A hash mapping file extension (e.g., ".webp") to the data URI string (e.g., "data:image/webp;base64,...").
  #   Returns an empty hash if no supported images are found.
  def bitmap_image_data_url(source_relative_path)
    # Basic validation for relative path
    unless source_relative_path.match?(%r{\A[a-zA-Z0-9_./-]+\z}) && !source_relative_path.include?("..")
      Rails.logger.warn "Invalid characters or path traversal attempt in source relative path: #{source_relative_path}"
      return {}
    end

    source_root = Rails.root.join("app")
    preferred_extensions = %w[.avif .webp .png .jpg .jpeg .gif]
    results = {}

    preferred_extensions.each do |ext|
      potential_path = source_root.join("#{source_relative_path}#{ext}").cleanpath
      begin
        resolved_path = Pathname.new(File.realpath(potential_path))
      rescue Errno::ENOENT, Errno::EINVAL
        next
      end
      next unless resolved_path.to_s.start_with?(source_root.to_s) && resolved_path.file?

      mime_type = case ext
      when ".png" then "image/png"
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".gif" then "image/gif"
      when ".webp" then "image/webp"
      when ".avif" then "image/avif"
      else "application/octet-stream"
      end

      begin
        # Cache each encoded image by resolved path and file version
        results[ext] = Rails.cache.fetch([
          :bitmap_image_data_url,
          resolved_path.to_s,
          file_version(resolved_path)
        ].join(":"), expires_in: 7.days) do
          image_data = File.binread(resolved_path)
          encoded_data = Base64.strict_encode64(image_data)
          "data:#{mime_type};base64,#{encoded_data}"
        end
      rescue StandardError => e
        Rails.logger.error "Error reading or encoding bitmap image #{resolved_path}: #{e.message}"
        next
      end
    end

    Rails.logger.warn "No suitable bitmap images found for source path: #{source_relative_path} within #{source_root}" if results.empty?
    results
  end

  # Returns a srcset string for all available formats in the bitmap image hash.
  # Example: bitmap_image_srcset(bitmap_image_data_url('images/foo'))
  # => "data:image/avif;base64,... type(image/avif), data:image/webp;base64,... type(image/webp), ..."
  def bitmap_image_srcset(image_hash)
    return "" unless image_hash.is_a?(Hash)

    preferred = [
      [ ".avif", "image/avif" ],
      [ ".webp", "image/webp" ],
      [ ".png", "image/png" ],
      [ ".jpg", "image/jpeg" ],
      [ ".jpeg", "image/jpeg" ],
      [ ".gif", "image/gif" ]
    ]
    preferred.map { |ext, mime| image_hash[ext] && "#{image_hash[ext]} type(#{mime})" }.compact.join(", ")
  end

  # --- User Preference Helpers ---

  # Gets a user preference value, returning a default if not set or user is nil.
  def get_user_preference(key, default_value = nil)
    # Uses the current_account helper defined in ApplicationController
    current_account ? UserPreference.get(current_account.id, key) || default_value : default_value
  end

  # Checks if a specific tutorial/item is dismissed.
  # Delegates to the existing helper in ApplicationController for consistency.
  # (Assumes tutorial_dismissed? helper is available via helper_method)
  # def item_dismissed?(key)
  #   tutorial_dismissed?(key)
  # end

  # --- End User Preference Helpers ---

  # --- Umami Analytics Inlining Helpers ---

  # Inlines the Umami analytics script directly into the document
  # This maintains consistency with the site's existing inline mechanisms
  # and provides better privacy by avoiding external script requests
  def inline_umami_script
    return unless Rails.env.production?

    begin
      # Fetch the Umami script from cache or internal proxy
      script_content = fetch_umami_script_content
      return if script_content.blank?

      # Return the script wrapped in a script tag with proper attributes
      content_tag(:script,
                  # rubocop:disable Rails/OutputSafety
                  script_content.html_safe,
                  # rubocop:enable Rails/OutputSafety
                  {
                    type: "text/javascript",
                    'data-website-id': "f46b6f42-9743-4ef0-9e1f-b16833b02897",
                    async: true,
                    defer: true
                  })
    rescue StandardError => e
      # Log error but don't break page rendering
      Rails.logger.error "Failed to inline Umami script: #{e.message}"
      nil
    end
  end

  # --- End Umami Analytics Inlining Helpers ---

  # --- Enhanced Caching Helpers ---

  # Fragment cache helper with enhanced cache key generation
  # Usage: <%= cache_fragment("experience_#{experience.id}", experience, current_account) do %>
  def cache_fragment(key_prefix, *cache_dependencies, expires_in: 1.hour, &block)
    return capture(&block) if Rails.env.development?

    cache_key = generate_enhanced_cache_key(key_prefix, *cache_dependencies)
    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      capture(&block)
    end
  end

  # Generate cache key with automatic dependency resolution
  def generate_enhanced_cache_key(*parts)
    key_parts = []

    parts.each do |part|
      case part
      when ActiveRecord::Base
        # For models, include class name, id, and updated_at
        key_parts << "#{part.class.name.underscore}/#{part.id}/#{part.updated_at.to_i}"
      when String, Symbol, Numeric
        key_parts << part.to_s
      when Array
        key_parts << part.map { |p| generate_enhanced_cache_key(p) }.join("/")
      when Hash
        key_parts << part.sort.to_h.to_s
      when NilClass
        # Skip nil values
        next
      else
        # For other objects, use their string representation
        key_parts << part.to_s
      end
    end

    # Add locale and format for internationalized caching
    key_parts << I18n.locale.to_s
    key_parts << request.format.to_s if respond_to?(:request) && request

    key_parts.compact.join("/")
  end

  # Cache collection helper for rendering lists efficiently
  # Usage: <%= cache_collection(@experiences, "experience_list") do |experience| %>
  def cache_collection(collection, key_prefix, expires_in: 30.minutes, &block)
    return collection.map(&block) if Rails.env.development?

    results = collection.map do |item|
      cache_key = generate_enhanced_cache_key(key_prefix, item)
      Rails.cache.fetch(cache_key, expires_in: expires_in) do
        capture(item, &block)
      end
    end
    safe_join(results)
  end

  # Cache invalidation helper for views
  def invalidate_fragment_cache(key_prefix, *cache_dependencies)
    cache_key = generate_enhanced_cache_key(key_prefix, *cache_dependencies)
    Rails.cache.delete(cache_key)
  end

  # Conditional cache helper - only caches if condition is met
  def cache_if(condition, key_prefix, *cache_dependencies, expires_in: 1.hour, &block)
    if condition && !Rails.env.development?
      cache_fragment(key_prefix, *cache_dependencies, expires_in: expires_in, &block)
    else
      capture(&block)
    end
  end

  # --- End Enhanced Caching Helpers ---

  private

  # Renamed from inline_vite_asset_content to get_vite_asset_content for clarity
  # Now accepts manifest_key directly.
  def get_vite_asset_content(manifest_key, type:)
    manifest_path = ViteRuby.instance.manifest.path_for(manifest_key, type: type)

    return unless manifest_path

    return nil unless Rails.env.production?

      # We no longer inline assets in non-production environments, so bail early.

      # Production
      # In production, manifest_path includes the hash, e.g., 'application-buildhash.css'
      # It's relative to public/<public_output_dir>
      # ViteRuby.instance.config.public_output_dir is typically 'vite' or 'vite-production'
      base_dir = Rails.root.join("public", ViteRuby.instance.config.public_output_dir)
      # Ensure manifest_path is treated as relative to base_dir if it accidentally includes public_output_dir again
      relative_manifest_path = manifest_path.sub(%r{^/?#{Regexp.escape(ViteRuby.instance.config.public_output_dir)}/}, "")
      file_path = base_dir.join(relative_manifest_path)

      if File.exist?(file_path)
        # Cache raw asset content; key includes manifest version so it
        # naturally expires on deploy
        cache_key = [ :vite_inline, type, vite_manifest_version, relative_manifest_path ].join(":")
        Rails.cache.fetch(cache_key, expires_in: 24.hours) { File.read(file_path) }
      else
        Rails.logger.error "[ViteInline] Asset not found at #{file_path} (derived from manifest key: #{manifest_key}, manifest path: #{manifest_path})"
        nil
      end
  rescue StandardError => e
    Rails.logger.error "[ViteInline] Error in get_vite_asset_content for manifest key '#{manifest_key}': #{e.class} - #{e.message}\n#{e.backtrace.take(5).join("\n")}"
    nil
  end
  # --- End Vite Asset Inlining Helpers ---

  # Returns a cache-busting version for the current Vite manifest.
  # Uses mtime and size of the manifest.json so any deploy that changes assets
  # naturally invalidates the cache keys.
  def vite_manifest_version
    @vite_manifest_version ||= begin
      manifest_file = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, "manifest.json")
      if File.exist?(manifest_file)
        m = File.mtime(manifest_file).to_i
        s = File.size(manifest_file)
        "v#{m}-#{s}"
      else
        "v0"
      end
    end
  end

  # Enrich navigation items with SVG content from disk
  def enrich_nav_items_with_svgs(nav_items)
    Rails.logger.info "Enriching #{nav_items.length} nav items"
    enriched = nav_items.map do |item|
      if item[:icon]
        svg_content = svg_icon_content(item[:icon])
        Rails.logger.info "Enriching nav item #{item[:icon]}: SVG content length: #{svg_content.length}"
        enriched_item = item.merge(svg: svg_content)
        Rails.logger.info "Enriched item: #{enriched_item.inspect}"
        enriched_item
      else
        Rails.logger.info "Nav item has no icon: #{item.inspect}"
        item
      end
    end
    Rails.logger.info "Final enriched nav items: #{enriched.to_json}"
    enriched
  end

  # --- Favicon Inlining Helpers ---

  # Inlines a favicon as a data URI
  def inline_favicon(path)
    return nil if path.blank?

    # Get the actual file path
    file_path = favicon_file_path(path)
    return nil unless file_path && File.exist?(file_path)

    # Read the file content
    Rails.cache.fetch([
      :inline_favicon,
      file_path.to_s,
      file_version(file_path)
    ].join(":"), expires_in: 7.days) do
      content = File.read(file_path)
      # Determine MIME type based on file extension
      mime_type = favicon_mime_type(file_path)
      # Encode as base64 data URI
      "data:#{mime_type};base64,#{Base64.strict_encode64(content)}"
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to inline favicon #{path}: #{e.message}"
    nil
  end

  # Inlines a manifest file (JSON/XML) with favicon references converted to data URIs
  def inline_manifest(path)
    return nil if path.blank?

    # Look for manifest files in app/manifests directory
    filename = File.basename(path)
    file_path = Rails.root.join("app/manifests", filename)
    return nil unless File.exist?(file_path)

  content = File.read(file_path)

    case File.extname(path).downcase
    when ".json", ".webmanifest"
      # Parse JSON and update paths to be absolute or data URIs
      begin
        manifest_data = JSON.parse(content)

        # Get the base URL for absolute URLs
        base_url = "#{request.protocol}#{request.host_with_port}"

        # Update start_url and scope to be absolute URLs
        manifest_data["start_url"] = "#{base_url}#{manifest_data['start_url']}" if manifest_data["start_url"]&.start_with?("/")

        manifest_data["scope"] = "#{base_url}#{manifest_data['scope']}" if manifest_data["scope"]&.start_with?("/")

        # Update icon src paths to data URIs
        manifest_data["icons"]&.each do |icon|
          if icon["src"]&.start_with?("/")
            icon_data = inline_favicon(icon["src"])
            icon["src"] = icon_data if icon_data
          end
        end

        # Update shortcut URLs to be absolute
        manifest_data["shortcuts"]&.each do |shortcut|
          shortcut["url"] = "#{base_url}#{shortcut['url']}" if shortcut["url"]&.start_with?("/")

          # Update shortcut icon src paths
          shortcut["icons"]&.each do |icon|
            if icon["src"]&.start_with?("/")
              icon_data = inline_favicon(icon["src"])
              icon["src"] = icon_data if icon_data
            end
          end
        end

        cache_key = [ :inline_manifest_json, file_path.to_s, file_version(file_path), request.base_url ].join(":")
        Rails.cache.fetch(cache_key, expires_in: 12.hours) do
          updated_content = JSON.pretty_generate(manifest_data)
          "data:application/manifest+json;base64,#{Base64.strict_encode64(updated_content)}"
        end
      rescue JSON::ParserError => e
        Rails.logger.warn "Failed to parse manifest JSON #{path}: #{e.message}"
        nil
      end
    when ".xml"
      # For XML, update src attributes to use data URIs but return as inline content (not base64)
      # This is more efficient than base64 encoding XML
      updated_content = content.gsub(%r{src="(/[^"]+)"}) do |match|
        favicon_path = ::Regexp.last_match(1)
        icon_data = inline_favicon(favicon_path)
        icon_data ? "src=\"#{icon_data}\"" : match
      end
      cache_key = [ :inline_manifest_xml, file_path.to_s, file_version(file_path), request.base_url ].join(":")
      Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        # Return as data URI with charset for proper XML handling
        "data:application/xml;charset=utf-8,#{ERB::Util.url_encode(updated_content)}"
      end
    else
      Rails.logger.warn "Unsupported manifest file type: #{path}"
      nil
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to inline manifest #{path}: #{e.message}"
    nil
  end

  # Resolves favicon path to actual file system path
  def favicon_file_path(path)
    return unless path.is_a?(String)

    # Prefer Vite-managed assets for all favicon/static asset lookups
    cache_key = [ :favicon_file_path, path, vite_manifest_version ].join(":")
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      if path.start_with?("@")
      asset_path = "images/#{path.sub('@', '')}"
      vite_asset_path_to_file(asset_path) ||
        Rails.root.join("app", "images", File.basename(path)) ||
        Rails.root.join("app", "assets", "static", File.basename(path))
      elsif path.start_with?("~/")
      vite_asset_path_to_file(path) ||
        Rails.root.join("app", "images", File.basename(path)) ||
        Rails.root.join("app", "assets", "static", File.basename(path))
      elsif path.start_with?("/assets/static/")
      Rails.root.join("app", "assets", "static", File.basename(path)) ||
        Rails.root.join("app", "images", File.basename(path))
      elsif path.start_with?("/")
      vite_asset_path_to_file(path) ||
        Rails.root.join("app", "images", File.basename(path)) ||
        Rails.root.join("public#{path}") ||
        Rails.root.join("app", "assets", "static", File.basename(path))
      else
      vite_asset_path_to_file(path) ||
        Rails.root.join("app", "images", File.basename(path)) ||
        Rails.root.join("public", path) ||
        Rails.root.join("app", "assets", "static", File.basename(path))
      end
    end
  end

  # Converts vite asset path to file system path
  def vite_asset_path_to_file(asset_path)
    if Rails.env.development?
      # In development, assets are in their source directories
      if asset_path.start_with?("images/")
        Rails.root.join("app", asset_path)
      elsif asset_path.start_with?("static/")
        Rails.root.join("app", asset_path)
      elsif asset_path.start_with?("icons/")
        Rails.root.join("app", asset_path)
      else
        # Try images directory as fallback
        Rails.root.join("app", "images", File.basename(asset_path))
      end
    else
      # In production, use vite manifest to find compiled assets
      begin
        manifest_path = Rails.root.join("public/vite/.vite/manifest.json")
        if File.exist?(manifest_path)
          manifest = JSON.parse(File.read(manifest_path))
          entry = manifest[asset_path]
          Rails.root.join("public", "vite", "assets", entry["file"]) if entry && entry["file"]
        end
      rescue StandardError => e
        Rails.logger.warn "Failed to resolve vite asset path #{asset_path}: #{e.message}"
        nil
      end
    end
  end

  # Determines MIME type for favicon files
  def favicon_mime_type(file_path)
    case File.extname(file_path).downcase
    when ".ico"
      "image/x-icon"
    when ".png"
      "image/png"
    when ".svg"
      "image/svg+xml"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".gif"
      "image/gif"
    when ".webp"
      "image/webp"
    when ".avif"
      "image/avif"
    else
      "application/octet-stream"
    end
  end

  # --- End Favicon Inlining Helpers ---

  def fetch_umami_script_content
  # Use Rails cache to avoid fetching the script on every request
  cache_key = [ :umami_script, request.base_url, vite_manifest_version ].join(":")
  Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      fetch_umami_script_from_source
  end
  end

  def fetch_umami_script_from_source
    # Use the internal proxy endpoint instead of external URL
    # This maintains consistency with the site's proxy architecture
    uri = "#{request.base_url}/umami/script.js"

    response = HTTParty.get(uri,
                            timeout: 10,
                            open_timeout: 5,
                            headers: {
                              "User-Agent" => "LibreverseInliner/1.0"
                            })

    if response.code == 200
      response.body
    else
      Rails.logger.error "Failed to fetch Umami script: HTTP #{response.code}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching Umami script: #{e.message}"
    nil
  end

  # --- End Umami Analytics Inlining Helpers ---
end

  # Lightweight file version string from mtime and size
  def file_version(path)
    p = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
    return "0-0" unless p.exist?

    "#{p.mtime.to_i}-#{p.size}"
  end
