require "voight_kampff"

class RodauthController < ApplicationController
  include EnhancedSpamProtection

  # Used by Rodauth for rendering views, CSRF protection, running any
  # registered action callbacks and rescue handlers, instrumentation etc.

  # Custom authentication handling for auth forms
  before_action :apply_bot_protection_to_auth_forms, if: -> { request.post? }
  before_action :apply_invisible_captcha_to_auth_forms, if: -> { request.post? }
  # Apply ActiveHashcash to auth forms
  before_action :apply_hashcash_to_auth_forms, if: -> { request.post? } # Controller callbacks and rescue handlers will run around Rodauth endpoints.
  # before_action :verify_captcha, only: :login, if: -> { request.post? }
  # rescue_from("SomeError") { |exception| ... }

  # Layout can be changed for all Rodauth pages or only certain pages.
  # layout "authentication"
  # layout -> do
  #   case rodauth.current_route
  #   when :login, :create_account, :verify_account, :verify_account_resend,
  #        :reset_password, :reset_password_request
  #     "authentication"
  #   else
  #     "application"
  #   end
  # end

  before_action :log_rodauth_action
  before_action :set_request

  # Add after_action to handle redirects for Turbo Stream logins
  # Target the :login action, as this is how Rails identifies the action for the /login route
  # after_action :handle_login_redirect, only: :login, if: -> { request.post? }

  def log_rodauth_action
    Rails.logger.info "DEBUG: [RodauthController] Action #{action_name} triggered for route: #{rodauth.current_route}, method: #{request.request_method}"
    # Removed secret_key_base hash logging to avoid leaking derived secrets
  end

  private

  def set_request
    @request = request
  end

  # Apply bot protection to auth forms (duplicated from EnhancedSpamProtection for auth routes)
  def apply_bot_protection_to_auth_forms
    return unless rodauth.respond_to?(:current_route)

    case rodauth.current_route
    when :login, :create_account, :change_password, :reset_password
      # Apply the same bot detection logic as EnhancedSpamProtection
      check_bot_protection_for_auth
    end
  end

  # Apply invisible captcha validation based on the current Rodauth route
  def apply_invisible_captcha_to_auth_forms
    return unless rodauth.respond_to?(:current_route)

    case rodauth.current_route
    when :login, :create_account, :change_password, :reset_password
      # Manually trigger invisible captcha validation for these forms
      validate_invisible_captcha!
    end
  end

  # Apply ActiveHashcash validation based on the current Rodauth route
  def apply_hashcash_to_auth_forms
    return unless rodauth.respond_to?(:current_route)

    case rodauth.current_route
    when :login, :create_account, :change_password, :reset_password
      # Use custom hashcash validation with more permissive date range
      validate_hashcash_custom
    end
  end

  # Custom hashcash validation with better date handling
  def validate_hashcash_custom
    return if hashcash_param.blank?

    Rails.logger.info "[HASHCASH DEBUG] Validating stamp: #{hashcash_param}"
    Rails.logger.info "[HASHCASH DEBUG] Resource: #{hashcash_resource}, Bits: #{hashcash_bits}"

    # First, let's validate the stamp format and difficulty manually
    begin
      stamp_parts = hashcash_param.split(":")
      Rails.logger.info "[HASHCASH DEBUG] Stamp parts: #{stamp_parts.inspect}"

      if stamp_parts.length == 7
        version, bits, date, resource, extension, rand, counter = stamp_parts
        Rails.logger.info "[HASHCASH DEBUG] Parsed - Version: #{version}, Bits: #{bits}, Date: #{date}, Resource: #{resource}, Extension: #{extension}, Rand: #{rand}, Counter: #{counter}"

        # Check if the stamp meets the difficulty requirement manually
        require "digest"
        hash = Digest::SHA1.hexdigest(hashcash_param)
        leading_zeros = hash.match(/^0*/)[0].length * 4 # Each hex digit = 4 bits
        Rails.logger.info "[HASHCASH DEBUG] Hash: #{hash}, Leading zeros (bits): #{leading_zeros}, Required: #{bits}"

        if leading_zeros >= bits.to_i
          Rails.logger.info "[HASHCASH DEBUG] Stamp meets difficulty requirement"
        else
          Rails.logger.warn "[HASHCASH DEBUG] Stamp does NOT meet difficulty requirement"
        end
      else
        Rails.logger.error "[HASHCASH DEBUG] Invalid stamp format - expected 7 parts, got #{stamp_parts.length}"
      end
    rescue StandardError => e
      Rails.logger.error "[HASHCASH DEBUG] Error parsing stamp: #{e.message}"
    end

    attrs = {
      ip_address: hashcash_ip_address,
      request_path: hashcash_request_path,
      context: hashcash_stamp_context
    }

    # Use a more permissive date range - allow stamps from yesterday and today
    # This prevents issues with timezone differences and allows for reasonable clock skew
    min_date = Date.current - 1.day
    Rails.logger.info "[HASHCASH DEBUG] Min date: #{min_date}, Current date: #{Date.current}"

    if ActiveHashcash::Stamp.spend(hashcash_param, hashcash_resource, hashcash_bits, min_date, attrs)
      Rails.logger.info "[HASHCASH] Valid stamp accepted - " \
                        "IP: #{hashcash_ip_address}, " \
                        "Path: #{hashcash_request_path}, " \
                        "Stamp: #{hashcash_param}"
    else
      Rails.logger.warn "[HASHCASH] Invalid stamp rejected - " \
                         "IP: #{hashcash_ip_address}, " \
                         "Path: #{hashcash_request_path}, " \
                         "Stamp: #{hashcash_param}"
      hashcash_after_failure
    end
  rescue StandardError => e
    Rails.logger.error "[HASHCASH] Error validating stamp: #{e.message}"
    Rails.logger.error "[HASHCASH] Backtrace: #{e.backtrace.first(3).join('\n')}"
    hashcash_after_failure
  end

  # Override hashcash failure handling for Rodauth controller
  def hashcash_after_failure
    Rails.logger.warn "[SPAM DETECTED] #{
      {
        spam_type: 'hashcash',
        ip: request.remote_ip,
        user_agent: request.user_agent,
        path: request.fullpath,
        method: request.request_method,
        timestamp: Time.current.utc.iso8601,
        detection_method: 'active_hashcash',
        hashcash_param: hashcash_param,
        hashcash_resource: hashcash_resource,
        hashcash_bits: hashcash_bits
      }.to_json
    }"

    flash[:alert] = if Rails.env.development?
      "Development: Hashcash validation failed. Please try again."
    else
      t("spam_protection.hashcash_failed",
        default: "Security validation failed. Please ensure JavaScript is enabled and try again.")
    end

    redirect_to rodauth_retry_path
  end

  # Manual invisible captcha validation
  def validate_invisible_captcha!
    return unless request.post?

    # Check honeypot field
    honeypot_key = params.keys.find { |key| key.match?(/^[a-f0-9]{8,}$/) && key != "invisible_captcha_timestamp" }
    if honeypot_key && params[honeypot_key].present?
      handle_honeypot_spam
      return
    end

    # Check timestamp
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
        threshold = 2 # seconds

        if (current_time - submitted_time) < threshold
          handle_timestamp_spam
          return
        end
      end
      nil
  end

  # Bot detection check for auth routes (duplicated from EnhancedSpamProtection)
  def check_bot_protection_for_auth
    Rails.logger.info "[RodauthController] Running bot detection checks for IP: #{request.remote_ip}, Path: #{request.fullpath}"

    # Check if botd cookie indicates this is a bot
    Rails.logger.info "[RodauthController] Checking botd cookie - Value: #{cookies[:botd].inspect}"
    if bot_detection_cookie_indicates_bot?
      log_spam_attempt_for_auth(:bot_cookie, {
                                  detection_method: "botd_cookie",
                                  cookie_value: cookies[:botd]
                                })

      flash[:alert] = if Rails.env.development?
        "Development: Bot detection cookie indicates bot behavior."
      else
        t("spam_protection.bot_detected",
          default: "Automated behavior detected. Please try again.")
      end

      redirect_to_safe_location_for_auth
      return false
    end
    Rails.logger.info "[RodauthController] botd cookie check passed"

    # Check if user agent is detected as bot by voight-kampff
    Rails.logger.info "[RodauthController] Checking user agent with voight-kampff - UA: #{request.user_agent}"
    if user_agent_indicates_bot?
      log_spam_attempt_for_auth(:bot_user_agent, {
                                  detection_method: "voight_kampff",
                                  user_agent: request.user_agent
                                })

      flash[:alert] = if Rails.env.development?
        "Development: User agent detected as bot by voight-kampff."
      else
        t("spam_protection.bot_detected",
          default: "Automated behavior detected. Please try again.")
      end

      redirect_to_safe_location_for_auth
      return false
    end
    Rails.logger.info "[RodauthController] voight-kampff user agent check passed"

    Rails.logger.info "[RodauthController] All bot detection checks passed"
    true
  end

  # Check if bot detection cookie indicates this is a bot (duplicated from EnhancedSpamProtection)
  def bot_detection_cookie_indicates_bot?
    botd_value = cookies[:botd]
    return false if botd_value == "0"

    true
  end

  # Check if user agent is detected as bot by voight-kampff (duplicated from EnhancedSpamProtection)
  def user_agent_indicates_bot?
    return false if request.user_agent.blank?

    begin
      VoightKampff.bot?(request.user_agent)
    rescue StandardError => e
      Rails.logger.error "[RodauthController] Error in bot detection: #{e.message}"
      false
    end
  end

  # Log spam attempts for auth routes
  def log_spam_attempt_for_auth(spam_type, additional_data = {})
    Rails.logger.warn "[SPAM] #{spam_type.upcase} detected in auth - " \
                      "IP: #{request.remote_ip}, " \
                      "Path: #{request.fullpath}, " \
                      "Additional: #{additional_data.inspect}"
  end

  # Redirect to safe location for auth routes
  def redirect_to_safe_location_for_auth
    redirect_to rodauth_retry_path
  end

  def rodauth_retry_path
    return rodauth.login_path unless rodauth.respond_to?(:current_route)

    case rodauth.current_route
    when :create_account
      rodauth.create_account_path
    when :change_password
      rodauth.change_password_path
    when :reset_password
      if rodauth.respond_to?(:reset_password_request_path)
        rodauth.reset_password_request_path
      else
        rodauth.login_path
      end
    else
      rodauth.login_path
    end
  end

=begin
  def handle_login_redirect
    # Only proceed if login was successful and it was a Turbo Stream request
    return unless rodauth.logged_in?
    return unless request.format.turbo_stream?
    # Also, don't interfere if Rodauth/Roda already set a redirect response (e.g., for pwned password)
    return if response.redirect?

    target_path = rodauth.login_redirect
    Rails.logger.info "[RodauthController] Successful login (Turbo Stream), redirecting via 303 to: #{target_path}"
    redirect_to target_path, status: :see_other
  end
=end
end
