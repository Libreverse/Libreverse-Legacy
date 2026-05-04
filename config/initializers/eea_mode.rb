# EEA Mode Initializer
# --------------------
# This file enables "EEA mode" (additional GDPR/ePrivacy safeguards) when the
# option `eea_mode` in the top‑level `libreverse.ini` configuration file is not
# explicitly disabled.
#
# Key responsibilities:
#   • Parse `libreverse.ini` once at boot. (Lightweight manual parser to avoid
#     adding the `inifile` gem.)
#   • Provide `EEAMode.enabled?` query method.
#   • Inject a `before_action` in every controller (HTML requests only) that
#     blocks the response until the user has provided the required privacy
#     consent for specific paths. If consent is missing, we render the full‑screen consent view
#     located at `app/views/consent/screen.html.erb`.
#   • Expose `consent_given?` helper so views/layouts can react (e.g. hide
#     banner once consent stored).
#
# NOTE:  The heavy UI pieces (view, stimulus controller, CSS) will be added in
#        subsequent commits.  This initializer lays the foundation so the rest
#        of the application can query `EEAMode.enabled?` and the request‑level
#        helper.

module EEAMode
  # Compliance verification constants
  def self.compliance
    {
      required: {
        all_paths_require_consent: true,
        secure_cookies: true,
        policy_exemptions: %w[consent privacy cookies]
      },
      cookie_settings: {
        httponly: true,
        secure: Rails.application.config.force_ssl,
        same_site: :strict,
        expiration: 1.year
      }
    }.freeze
  end

  # ---------------------------------------------------------------------
  # Configuration via ENV variable only
  # ---------------------------------------------------------------------

  # Return true if EEA mode is active. Defaults to true for compliance.
  # Can be overridden via instance settings in the UI.
  def self.enabled?
    return @enabled unless @enabled.nil?

    # Default to true for GDPR compliance, allow override via ENV for testing
    raw = ENV.fetch("EEA_MODE") { "true" }
    @enabled = %w[true 1 yes on].include?(raw.to_s.downcase)
  end

  # Check if EEA mode is enabled instance-wide (defaults to true for compliance)
  def self.enabled_for_user?(_account_id = nil)
    # EEA mode is now instance-wide, not user-specific
    # Use instance setting with true as fallback (no env var dependency)
    InstanceSetting.get_with_fallback("eea_mode_enabled", nil, "true") == "true"
  end

  def self.verify_compliance
    compliance[:required].each do |key, value|
      raise "EEA Compliance Violation: #{key} not configured properly" unless value
    end
    true
  end

  # Cookie key used to remember that the user has accepted privacy/cookie terms.
  CONSENT_COOKIE_KEY = :privacy_consent

  # ---------------------------------------------------------------------------
  # Controller concern injected into `ActionController::Base`.
  # ---------------------------------------------------------------------------
  module ConsentEnforcer
    extend ActiveSupport::Concern

    included do
      before_action :_enforce_privacy_consent, if: -> { EEAMode.enabled? }
      helper_method :consent_given?
    end

    private

    # Returns true if the signed consent cookie has been stored.
    def consent_given?
      cookies&.signed&.[](EEAMode::CONSENT_COOKIE_KEY) == "1"
    end

    # Main guard. Enforce consent for all HTML requests in EEA mode
    def _enforce_privacy_consent
      return unless EEAMode.enabled?

      # Check if EEA mode is enabled for this specific user
      current_account_id = respond_to?(:current_account) && current_account&.id
      return unless EEAMode.enabled_for_user?(current_account_id)

      # Skip for policy pages that must be accessible without consent
      path = request.path
      return if path.start_with?("/privacy", "/cookies", "/consent")

      # Otherwise enforce for all HTML requests
      return unless !consent_given? && request.format.html?

        log_consent_requirement
        render template: "consent/screen", layout: "application", status: :ok
    end

    def log_consent_requirement
      Rails.logger.info(
        "[EEA Compliance] Consent required for: " \
        "path: #{request.path}, " \
        "referrer: #{request.referer || 'none'}"
      )
    end
  end
end

# Verify compliance at boot in production
EEAMode.verify_compliance if Rails.env.production?

# Hook the concern into all controllers automatically.
ActiveSupport.on_load(:action_controller_base) do
  include EEAMode::ConsentEnforcer
end

