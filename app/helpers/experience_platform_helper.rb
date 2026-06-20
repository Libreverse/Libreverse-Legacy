module ExperiencePlatformHelper
  PLATFORM_SCRIPT_PATH = Rails.root.join("app/javascript/libs/libreverse_platform.js")
  STORAGE_SCRIPT_PATH = Rails.root.join("app/javascript/libs/storage_access.js")
  PERMISSIONS_SCRIPT_PATH = Rails.root.join("app/javascript/libs/permissions_handler.js")
  KEYBOARD_SCRIPT_PATH = Rails.root.join("app/javascript/libs/keyboard_lock_handler.js")

  EXPERIENCE_IFRAME_SANDBOX = "allow-scripts allow-pointer-lock allow-same-origin allow-storage-access allow-forms allow-modals allow-orientation-lock".freeze
  EXPERIENCE_IFRAME_ALLOW = "pointer-lock storage-access camera microphone accelerometer gyroscope magnetometer geolocation forms modals orientation-lock".freeze

  def prepare_experience_html(html_content)
    scripts = [
      inline_script_tag(File.read(STORAGE_SCRIPT_PATH)),
      inline_script_tag(File.read(PERMISSIONS_SCRIPT_PATH)),
      inline_script_tag(File.read(KEYBOARD_SCRIPT_PATH)),
      "<script>window.__LIBREVERSE_COLLAB_SCRIPT_URL__=#{multiplayer_collab_script_url.to_json};</script>",
      inline_script_tag(File.read(PLATFORM_SCRIPT_PATH))
    ]

    inject_client_scripts(html_content, *scripts)
  end

  def multiplayer_experience_path(experience)
    display_experience_path(
      experience,
      session: "exp_#{experience.id}_#{SecureRandom.hex(8)}"
    )
  end

  private

  def inline_script_tag(source)
    "<script>#{source}</script>"
  end

  def multiplayer_collab_script_url
    ViteRuby.instance.manifest.path_for("experience_multiplayer_collab.js")
  rescue StandardError
    "/#{ViteRuby.config.public_output_dir}/experience_multiplayer_collab.js"
  end

  def ensure_html_document(html_content)
    return html_content if html_content.match?(/<html[\s>]/i)

    <<~HTML.strip
      <!DOCTYPE html>
      <html>
        <head><meta charset="utf-8"></head>
        <body>#{html_content}</body>
      </html>
    HTML
  end

  def inject_client_scripts(html_content, *script_tags)
    content = ensure_html_document(html_content)
    block = "#{script_tags.join("\n")}\n"

    if content.include?("</head>")
      content.sub("</head>", "#{block}</head>")
    elsif content.include?("</body>")
      content.sub("</body>", "#{block}</body>")
    else
      content + block
    end
  end
end
