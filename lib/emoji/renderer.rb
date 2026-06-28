module Emoji
  module Renderer
    module_function

    require "cgi"
    require "erb"
    require "digest/sha1"
    require "uri"
    require "httparty"

    # Matches standard emojis, including sequences with ZWJ and skin tone modifiers. Note that it's an exception to the general re2 use rule as the identifiers it needs aren't supported by RE2.
    EMOJI_REGEX = /(?:\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?(?:\u{200D}\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

    DEFAULT_CACHE_EXPIRY = 1.week.to_i

    # Public: Replaces any emoji characters found in +input+ with inline SVG <img> tags.
    # Returns the processed String (not HTML-safe).
    def replace(input, cache_expiry: DEFAULT_CACHE_EXPIRY)
      str = input.to_s
      return input unless str.match?(EMOJI_REGEX)

      str.gsub(EMOJI_REGEX) do |emoji|
        key      = cache_key(emoji)
        stored   = Rails.cache.read(key)
        cache_hit = !stored.nil?

        tag = stored

        if tag.blank?
          tag = build_img_tag(emoji)
          if tag.present?
            Rails.cache.write(key, tag, expires_in: cache_expiry)
          elsif cache_hit
            Rails.cache.delete(key)
          end
        end

        tag.presence || emoji
      end
    end

    # Public: Builds the inline SVG <img> tag for a given +emoji+ character.
    # Returns the String markup or nil if the underlying SVG file could not be found.
    def build_img_tag(emoji)
      svg_content = fetch_svg_for_emoji(emoji)
      return nil if svg_content.blank?

      encoded_svg = ERB::Util.url_encode(svg_content)
      %(<img src="data:image/svg+xml,#{encoded_svg}" alt="#{CGI.escapeHTML(emoji)}" class="emoji" loading="eager" decoding="sync" fetchpriority="high" draggable="false" tabindex="-1">)
    rescue StandardError => e
      Rails.logger.error "Emoji::Renderer#build_img_tag – #{e.class}: #{e.message}"
      nil
    end

    # Internal: Computes a Rails-cache compatible key for an emoji.
    def cache_key(emoji)
      "emoji_renderer/v1/#{Digest::SHA1.hexdigest(emoji)}"
    end

    # Internal: Retrieves the raw SVG markup for +emoji+ from Vite's manifest/asset pipeline.
    # Handles both dev-server (HTTP) and production (static file) scenarios.
    def fetch_svg_for_emoji(emoji)
      codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")

      begin
        svg_path = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg", type: :image)
        content  = read_vite_asset_content(svg_path)
        return content if content.present?
      end

      dev_fallback_path = Rails.root.join("app/emoji", "#{codepoints}.svg")
      return File.read(dev_fallback_path) if File.exist?(dev_fallback_path)

      Rails.logger.warn { "[Emoji::Renderer] SVG file not found for emoji #{emoji.inspect} (#{codepoints})" }
      nil
    end

    # Internal: Reads the file referenced by +manifest_path+ respecting the current environment.
    def read_vite_asset_content(manifest_path)
      return if manifest_path.blank?

      if Rails.env.development? || Rails.env.test?
        # Construct the development server URL using host_with_port
        dev_url = "http://#{ViteRuby.config.host_with_port}#{manifest_path}"
        HTTParty.get(dev_url).body
      else
        relative  = manifest_path.sub(%r{^/?#{ViteRuby.instance.config.public_output_dir}/}, "")
        file_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, relative)
        if File.exist?(file_path)
          File.read(file_path)
        elsif defined?(B2AssetsStorage) && B2AssetsStorage.cdn_urls?
          B2AssetsStorage.read_public_object(relative)
        end
      end
    rescue StandardError => e
      Rails.logger.error "Emoji::Renderer#read_vite_asset_content – #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
      nil
    end
  end
end
