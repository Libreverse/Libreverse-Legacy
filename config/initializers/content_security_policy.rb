# Content Security Policy Configuration
Rails.application.configure do
  config.content_security_policy do |policy|
    # Base directives
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.manifest_src :self, :data # Allow inlined manifests as data URIs

    # ---- Dynamic script/style directives ----
    script_sources = %i[self https unsafe_inline unsafe_eval data blob]
    style_sources  = %i[self https unsafe_inline data]

    # Removed nonce requirement to allow inline scripts/styles since our app inlines large Vite bundles.

    policy.script_src(*script_sources)
    policy.style_src(*style_sources)
    policy.worker_src :self, :blob

    # Dev-only extra allowances (eval + websocket)
    if Rails.env.development?
      policy.script_src(*policy.script_src, :unsafe_eval)
      policy.worker_src(*policy.worker_src, :unsafe_eval)

      # When skipProxy=true the Vite dev server is a different origin (port 3001) so :self no longer matches.
      # Allow both localhost and 127.0.0.1 variants to cover host customizations applied later in init order.
      vite_dev_ports = [ 3001 ]
      vite_hosts = %w[localhost 127.0.0.1]
      vite_http_origins = vite_hosts.product(vite_dev_ports).map { |h, p| "http://#{h}:#{p}" }

      # Script + style tags, dynamic module fetches, CSS HMR, and source map fetches
      policy.script_src(*policy.script_src, *vite_http_origins)
      policy.style_src(*policy.style_src, *vite_http_origins)

      # connect-src needs HTTP (module preloads / import analysis requests) and WS for HMR
      policy.connect_src(*policy.connect_src, *vite_http_origins)
      policy.connect_src(*policy.connect_src, *vite_http_origins.map { |o| o.sub("http://", "ws://") })
    end

    # Allow generic WebSocket scheme (ws:) so localhost or custom ports work when not using SSL
    policy.connect_src(*policy.connect_src, :self, :https, :data, "ws:")

    # Iframes for Experience viewer (data-URI) remain allowed.
    policy.frame_src :self, :data

    # Allow any subdomain of the configured instance domain to embed this app.
    # Uses frame_ancestors (the modern replacement for X-Frame-Options) so wildcard subdomains work.
    # Evaluated per-request via proc so the domain is read after full initialization (DB accessible).
    policy.frame_ancestors :self, :data, -> {
      bare_domain = LibreverseInstance.instance_domain.sub(/:\d+$/, "")
      [ "https://#{bare_domain}", "https://*.#{bare_domain}",
        "http://#{bare_domain}", "http://*.#{bare_domain}" ]
    }

    # Test allowances – blob URIs used by rails system tests
    policy.script_src(*policy.script_src, :blob) if Rails.env.test?

    # Report CSP violations (Report‑Only first, then enforce)
    policy.report_uri "/csp-report"
  end

  # Configure a default Permissions-Policy (removing browsing-topics if it was added by default)
  config.permissions_policy do |policy|
    policy.accelerometer :self
    policy.autoplay :self
    policy.camera :self
    policy.display_capture :self
    policy.encrypted_media :self
    policy.fullscreen :self
    policy.geolocation :self
    policy.gyroscope :self
    policy.magnetometer :self
    policy.microphone :self
    policy.midi :none
    policy.payment :none
    policy.picture_in_picture :self
    policy.screen_wake_lock :self
    policy.sync_xhr :self
    policy.usb :self
  end

  # Initially ran in report‑only mode; switched to false after verifying
  config.content_security_policy_report_only = false
end
