class ApplicationController < ActionController::Base
  include CableReady::Broadcaster
  include PasswordSecurityEnforcer
  include Loggable
  include SpamDetection
  include WebsocketP2pHelper
  include EnhancedCaching

  # CanCanCan integration
  include CanCan::ControllerAdditions

  helper_method :current_account, :current_ability, :user_signed_in?, :authenticated_user?, :guest_user?, :can_create_content?
  helper_method :privacy_policy_path, :blog_url, :recent_blog_posts
  helper_method :profiling_enabled?

  # Protection from CSRF
  protect_from_forgery with: :exception

  # Global spam protection as a safety net
  before_action :global_spam_protection_check

  before_action :disable_browser_cache, if: -> { Rails.env.development? }
  before_action :initialize_guest_preferences
  before_action :log_request_info
  after_action :log_response_info
  after_action :set_compliance_headers, if: -> { EEAMode.enabled? }
  after_action :apply_automatic_caching
  before_action :set_current_ip
  before_action :set_locale

  helper_method :tutorial_dismissed?, :consent_given?, :consent_path

  def current_account
    # Use Current.account if available (set by ApplicationReflex)
    return Current.account if Current.account

    # Request-local memoization to avoid multiple DB hits in one request
    if (acc = request.env["libreverse.current_account"])
      return acc
    end

    # Otherwise get account_id from session (like GraphqlController pattern)
    account_id = session[:account_id] || request.env["rack.session"]&.[](:account_id)
    return nil unless account_id

    account = Account.find(account_id)

    unless account
      # Account ID in session doesn't exist in DB - invalid session
      Rails.logger.warn "[ApplicationController] Account ID '#{account_id}' found in session does not exist in DB. Clearing session and instructing cookie clear."

      # Check if we recently sent a cookie clear instruction to prevent loops
      cache_key = "cookie_clear_sent_#{account_id}_#{request.remote_ip}"
      recently_sent = Rails.cache.read(cache_key)

      unless recently_sent
        # Mark that we've sent this instruction recently
        Rails.cache.write(cache_key, true, expires_in: 60.seconds)

        # Clear the session
        reset_session

        # Set response header to instruct browser to clear cookies
        response.headers["X-Clear-Cookies"] = "invalid-session"
        response.headers["X-Reload-Required"] = "true"
      end

      return nil
    end

    request.env["libreverse.current_account"] = account
    account
  end

  private

    # Whether rack-mini-profiler is enabled for the current session.
    # In production, admins have it on by default unless they explicitly
    # force-disable it for their session. Non-admins can enable it temporarily
    # via the Admin::ProfilingController (TTL based).
    def profiling_enabled?
      data = session[:profiling]
      if data.is_a?(Hash)
        # Force-disabled override (with TTL)
        if data[:force_disabled]
          exp = data[:expires_at]
          return false if exp && Time.now.to_i < exp.to_i
        end

        # Explicit enablement (with TTL)
        if data[:enabled]
          exp = data[:expires_at]
          return true if exp && Time.now.to_i < exp.to_i
        end
      end

      # Default-on for admins in production
      Rails.env.production? && current_account&.admin? ? true : false
    end

    def privacy_policy_path
      privacy_path
    end

    def set_compliance_headers
      # Use the host application's routes, even when inside an isolated engine
      privacy_path  = main_app.privacy_path
      cookies_path  = main_app.cookie_policy_path

      response.headers["X-Privacy-Policy"] = privacy_path
      response.headers["X-Cookie-Policy"] = cookies_path
      response.headers["X-Consent-Required"] = (!consent_given?).to_s
      response.headers["X-Consent-Status"] = consent_given? ? "accepted" : "pending"
    end

    def tutorial_dismissed?(key)
      # Always check UserPreference now
      current_account ? UserPreference.dismissed?(current_account.id, key) : false
      # Removed session check
    end

    def disable_browser_cache
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    # Initializes default preferences for guests if not already set
    def initialize_guest_preferences
      # Ensure this runs only if we have a current_account (guest or user)
      return unless current_account

      # Check/set drawer state only if it's a guest account
      nil unless current_account.guest?

      # Add other guest-specific preference initializations here if needed

      # Removed session initialization
    end

    def log_request_info
      log_info("Request started: #{request.method} #{request.fullpath}")
      log_debug("Request params: #{request.filtered_parameters.inspect}")
      log_debug("User agent: #{request.user_agent}")
    end

    def log_response_info
      log_info("Response completed: #{response.status}")
    end

    def set_current_ip
      Current.real_ip = request.env["remote_ip_original"] || request.remote_ip
      Current.ip = request.remote_ip
    end

    def set_locale
      I18n.locale =
        if current_account && (user_pref = UserPreference.get(current_account.id, "locale")).present?
          user_pref
        else
          extract_locale_from_accept_language_header || session[:locale] || I18n.default_locale
        end
    end

    def extract_locale_from_accept_language_header
      return unless request.headers["Accept-Language"]

      accepted = request.headers["Accept-Language"].scan(/[a-z]{2}(?=(-|;|,|$))/i).flatten.map(&:downcase)
      available = I18n.available_locales.map(&:to_s)
      accepted.find { |lang| available.include?(lang) }
    end

    # Helper methods for authentication
    def require_authentication
      return if current_account

      flash[:alert] = "You must be logged in to access this page."
      redirect_to "/login"
    end

    def require_admin
      return if current_account&.admin?

      flash[:alert] = "You must be an admin to perform that action."
      redirect_to root_path
    end

    # CanCanCan integration - override current_ability to use Account model
    def current_ability
      @current_ability ||= Ability.new(current_account)
    end

    # Enhanced authentication helpers for role-based access control
    def user_signed_in?
      current_account.present?
    end

    def authenticated_user?
      current_account.present? && current_account.effective_user?
    end

    def guest_user?
      current_account.present? && current_account.guest?
    end

    def require_authenticated_user
      return if authenticated_user?

        flash[:alert] = "You must be a registered user to access this page."
        redirect_to "/login"
    end

    def require_non_guest
      return unless guest_user?

        flash[:alert] = "This feature is not available for guest accounts."
        redirect_to root_path
    end

    # Content creation permissions helper
    def can_create_content?
      authenticated_user? && can?(:create, Experience)
    end

    # Helper method to get current instance domain
    def current_instance_domain
      @current_instance_domain ||= if LibreverseInstance::Application.respond_to?(:instance_domain)
          LibreverseInstance::Application.instance_domain
      else
          # Fallback during early initialization
          ENV["INSTANCE_DOMAIN"] || case Rails.env
                                    when "development"
                                      "localhost:3000"
                                    when "test"
                                      "localhost"
                                    else
                                      "localhost"
                                    end
      end
    end
    helper_method :current_instance_domain

    # Helper method to get current account's federated identifier
    def current_account_federated_id
      current_account&.federated_identifier || "@guest@#{current_instance_domain}"
    end
    helper_method :current_account_federated_id

    # Blog helper methods
    def blog_url
      "/blog"
    end

    def recent_blog_posts(limit: 5)
      return [] unless defined?(Comfy::Cms::Site)

      blog_site = Comfy::Cms::Site.find_by(identifier: "instance-blog")
      return [] unless blog_site

      blog_site.pages
               .published
               .where.not(parent_id: nil) # Exclude root page
               .order(created_at: :desc)
               .limit(limit)
               .map do |page|
        {
          title: page.fragments.find_by(identifier: "title")&.content&.strip&.gsub(/^---\s*/, "") || page.label,
          url: "/blog#{page.full_path}",
          published_at: page.fragments.find_by(identifier: "published_at")&.content&.strip&.gsub(/^---\s*['"]?|['"]?\s*$/, ""),
          excerpt: page.fragments.find_by(identifier: "meta_description")&.content&.strip&.gsub(/^---\s*/, "") || ""
        }
      end
    rescue StandardError => e
      Rails.logger.warn "Error fetching recent blog posts: #{e.message}"
      []
    end

    # Global spam protection method - acts as a safety net for forms that might bypass controller-specific protection
    def global_spam_protection_check
      return unless should_check_for_spam?
      return unless contains_invisible_captcha_fields?

      # Perform manual honeypot validation
      honeypot_key = params.keys.find { |key| key.match?(/^[a-f0-9]{8,}$/) && key != "invisible_captcha_timestamp" }
      if honeypot_key && params[honeypot_key].present?
        log_spam_attempt("honeypot", {
                           field: honeypot_key,
                           value: params[honeypot_key],
                           detection_method: "global_protection"
                         })

        flash[:alert] = "There was an error processing your request. Please try again."
        redirect_to_safe_location
        return
      end

      # Perform timestamp validation
      return if params[:invisible_captcha_timestamp].blank?

        raw_ts = params[:invisible_captcha_timestamp].to_s
        begin
          submitted_time = Time.iso8601(raw_ts)
        rescue ArgumentError
          # Fallback for legacy integer timestamps
          int_ts = raw_ts.to_i
          submitted_time = Time.at(int_ts).utc if int_ts.positive?
        end

        if submitted_time.present?
          current_time = Time.current.utc
          threshold = 4 # seconds - more lenient for global check

          if (current_time - submitted_time) < threshold
            log_spam_attempt("timestamp", {
                               timestamp: submitted_time.iso8601,
                               current_time: current_time.iso8601,
                               threshold: threshold,
                               detection_method: "global_protection"
                             })

            flash[:alert] = "Please wait a moment before submitting the form."
            redirect_to_safe_location
            return
          end
        end
        nil
    end

    # Check if we should perform global spam detection
    def should_check_for_spam?
      # Skip if controller already has invisible_captcha configured to prevent double-validation
      return false if invisible_captcha_configured?

      # Skip API endpoints
      return false if request.path.start_with?("/api/", "/graphql", "/xmlrpc")

      # Skip authentication paths (handled by RodauthController)
      return false if request.path.start_with?("/login", "/create-account", "/reset-password", "/change-password")

      # Skip non-state-changing requests
      return false unless request.post? || request.put? || request.patch?

      # Only check if this is likely a form submission
      true
    end

    # Check if current controller has invisible_captcha already configured
    def invisible_captcha_configured?
      return false unless self.class.respond_to?(:invisible_captcha_options)

      options = self.class.invisible_captcha_options
      options.present? && options[:only].present?
    end

    # Check if request contains invisible captcha fields
    def contains_invisible_captcha_fields?
      # Look for timestamp field or honeypot-style random hex fields
      return true if params[:invisible_captcha_timestamp].present?

      # Look for potential honeypot fields (random hex strings)
      params.keys.any? { |key| key.match?(/^[a-f0-9]{8,}$/) }
    end

    # Safe redirect that prevents open redirects
    def redirect_to_safe_location
      safe_path = request.referer&.start_with?(request.base_url) ? request.referer : root_path
      redirect_to safe_path
    end

    # Enhanced logging method for spam attempts
    def log_spam_attempt(spam_type, additional_data = {})
      log_data = {
        spam_type: spam_type,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        path: request.path,
        method: request.method,
        timestamp: Time.current.iso8601
      }.merge(additional_data)

      Rails.logger.warn "[SPAM DETECTED] #{log_data.to_json}"

      # Could also send to monitoring service here
      # SpamMonitoringService.record_attempt(log_data) if defined?(SpamMonitoringService)
    end

    # Used by audits1984 to identify the current auditor
    def find_current_auditor
      # Only allow admin accounts to audit
      current_account if current_account&.admin?
    end

  # Intelligent automatic caching based on response characteristics
  def apply_automatic_caching
    return if Rails.env.development? || Rails.env.test?
    return if response.headers["Cache-Control"].present? # Skip if already set
    return if skip_automatic_caching? # Skip if controller opted out
    return unless Rails.application.config.automatic_caching.enabled

    # Check for paths that should never be cached
    if Rails.application.config.automatic_caching.no_cache_patterns.any? { |pattern| request.path.match?(pattern) }
      set_no_cache_headers
      log_caching_decision("no-cache", "matches no-cache pattern") if should_log_decisions?
      return
    end

    # Determine response characteristics
    response_size = estimate_response_size
    is_authenticated = current_account.present?
    is_get_request = request.get?
    has_sensitive_data = sensitive_response_data?

    # Apply caching strategy based on characteristics
    if !is_get_request
      # Don't cache non-GET requests
      set_no_cache_headers
      log_caching_decision("no-cache", "non-GET request") if should_log_decisions?

    elsif has_sensitive_data
      # Sensitive data - minimal caching
      duration = Rails.application.config.automatic_caching.durations.sensitive
      set_cache_headers(
        duration: duration,
        public: false,
        must_revalidate: true
      )
      log_caching_decision("sensitive", "#{duration} private") if should_log_decisions?

    elsif response_size <= Rails.application.config.automatic_caching.turbocache_max_size && !is_authenticated
      # Small public responses - perfect for turbocache
      duration = Rails.application.config.automatic_caching.durations.turbocache
      set_turbocache_headers(duration: duration, must_revalidate: true)
      # Also set longer browser cache as fallback
      response.headers["Cache-Control"] += ", stale-while-revalidate=300"
      log_caching_decision("turbocache", "#{duration} public + 5min stale") if should_log_decisions?

    elsif response_size <= Rails.application.config.automatic_caching.turbocache_max_size && is_authenticated
      # Small private responses - short cache
      duration = Rails.application.config.automatic_caching.durations.small_private
      set_cache_headers(
        duration: duration,
        public: false,
        must_revalidate: true
      )
      log_caching_decision("small-private", "#{duration} private") if should_log_decisions?

    elsif response_size > Rails.application.config.automatic_caching.large_response_min_size
      # Large responses (likely 1MB+ HTML) - optimized for large content
      duration = if is_authenticated
  Rails.application.config.automatic_caching.durations.large_authenticated
      else
  Rails.application.config.automatic_caching.durations.large_public
      end

      set_large_response_cache_headers(
        duration: duration,
        public: !is_authenticated,
        respect_existing_compression: true
      )
      log_caching_decision("large", "#{duration} #{is_authenticated ? 'private' : 'public'}") if should_log_decisions?

    else
      # Medium responses - standard caching
      duration = if is_authenticated
  Rails.application.config.automatic_caching.durations.medium_authenticated
      else
  Rails.application.config.automatic_caching.durations.medium_public
      end

      set_cache_headers(
        duration: duration,
        public: !is_authenticated,
        must_revalidate: true,
        stale_while_revalidate: 30.seconds
      )
      log_caching_decision("medium", "#{duration} #{is_authenticated ? 'private' : 'public'}") if should_log_decisions?
    end
  end

  # Estimate response size for caching decisions
  def estimate_response_size
    body = response.body
    return 0 unless body

    # If body is a string, get its size
    return body.bytesize if body.respond_to?(:bytesize)

    # If body responds to join (like ActionView output), join and measure
    return body.join.bytesize if body.respond_to?(:join)

    # Default estimate for unknown body types
    1024 # 1KB default
  end

  # Check if response contains sensitive data that shouldn't be cached long
  def sensitive_response_data?
    # Check configured sensitive patterns
    Rails.application.config.automatic_caching.sensitive_patterns.any? do |pattern|
      request.path.match?(pattern)
    end ||

      # Check for user-specific content indicators
      params[:user_id].present? || params[:account_id].present? ||

      # Check response headers for sensitive content indicators
      (response.headers["Content-Type"]&.include?("application/json") && current_account)
  end

  # Set no-cache headers for sensitive or non-cacheable content
  def set_no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  # Check if caching decisions should be logged
  def should_log_decisions?
    Rails.application.config.automatic_caching.log_decisions
  end

  # Log caching decisions for debugging
  def log_caching_decision(strategy, details)
    Rails.logger.info "[AutoCache] #{request.method} #{request.path} -> #{strategy} (#{details})"
  end
end
