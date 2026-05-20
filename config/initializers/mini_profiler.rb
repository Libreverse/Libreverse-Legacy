if Rails.env.development? || Rails.env.production?
  require "rack-mini-profiler"

  # Base config
  Rack::MiniProfiler.config.position = "right"
  Rack::MiniProfiler.config.start_hidden = false # Show the profiler UI by default

  # Skip common static and dev-server paths (Vite, etc.)
  Rack::MiniProfiler.config.skip_paths ||= []
  Rack::MiniProfiler.config.skip_paths += [
    %r{assets/},
    %r{images/},
    /favicon\.ico$/,
    %r{packs/},
    %r{\A/vite-dev/},
    %r{\A/@vite/},
    %r{\A/vite/},
    %r{\A/node_modules/},
    %r{\A/\+virtual/},
    %r{\A/rails/active_storage/}
  ]

  # In production, enable the profiler by default for admin users.
  # Non-admin users must still explicitly enable it via Admin::ProfilingController
  # which sets a short-lived session flag (TTL) to avoid accidental exposure.
  if Rails.env.production?
    Rack::MiniProfiler.config.authorization_mode = :allow_authorized
    Rack::MiniProfiler.config.pre_authorize_cb = proc do |env|
      sess = env["rack.session"]
      # First, honor an explicit force-disabled override (admin can temporarily turn it off)
      if sess && sess[:profiling].is_a?(Hash)
        pd = sess[:profiling]
        if pd[:force_disabled]
          exp = pd[:expires_at]
          next false unless !exp || Time.now.to_i >= exp.to_i

            sess[:profiling] = nil

        end
      end

      # Allow admins by default
      begin
        if sess && (account_id = sess[:account_id])
          # Cheap admin check without loading full record
          is_admin = AccountSequel.where(id: account_id).get(:admin) == true
          next true if is_admin
        end
      rescue StandardError => e
        # Fail closed if anything goes wrong
        Rails.logger.debug("[MiniProfiler] admin check failed: #{e.class}: #{e.message}")
      end

      # Fallback to explicit session-based enablement with TTL (for non-admins or manual toggles)
      next false unless sess && sess[:profiling].is_a?(Hash)

      data = sess[:profiling]
      enabled = data[:enabled]
      expires_at = data[:expires_at]

      # Auto-expire and clean up
      if !expires_at || Time.now.to_i >= expires_at.to_i
        sess[:profiling] = nil
        next false
      end

      enabled == true
    end
  end

  # Persistent storage in Redis when available, else memory
  begin
    require "redis"
    url = ENV.fetch("REDIS_URL") { "redis://127.0.0.1:6379/0" }
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
    Rack::MiniProfiler.config.storage_options = { url: url }
  rescue LoadError
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  end

  # Insert middleware early for accurate timings, but avoid double insertion and
  # only do this when running the web server (not for jobs/console/rake).
  if defined?(Rails::Server)
    stack = Rails.application.config.middleware
    unless ENV["RACK_MINI_PROFILER_INSERTED"] == "1"
      begin
        if defined?(ViteRuby::DevServerProxy)
          # Ensure Mini Profiler runs after Vite Ruby's dev server proxy
          stack.insert_after ViteRuby::DevServerProxy, Rack::MiniProfiler
        else
          # Append to the end so it comes after most engine middlewares
          stack.use Rack::MiniProfiler
        end
      rescue StandardError
        # As a last resort, append
        stack.use Rack::MiniProfiler
      end
      ENV["RACK_MINI_PROFILER_INSERTED"] = "1"
    end
  end
end
