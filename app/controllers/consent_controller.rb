class ConsentController < ApplicationController
    include Turbo::Streams::ActionHelper

    # Configure invisible captcha for consent forms to prevent automated abuse
    # invisible_captcha only: %i[accept decline],
    # timestamp_threshold: 1 # Very short threshold for consent

    # Skip CSRF for consent flow but maintain spam protection
    skip_before_action :verify_authenticity_token

    # Add rate limiting as alternative protection
    before_action :rate_limit_consent_actions, only: %i[accept decline]

    # GET /consent/screen (or /consent)
    def screen
        render turbo_stream: turbo_stream.morph(".consent-overlay", render_to_string("consent/screen", layout: false))
    end

    # POST /consent/accept
    def accept
        remember_opt_in = params[:remember_opt_in] == "1"
        cookie_settings = EEAMode.compliance[:cookie_settings]

        # Set secure cookie with all recommended settings
        cookies.signed[EEAMode::CONSENT_COOKIE_KEY] = {
          value: "1",
          expires: cookie_settings[:expiration].from_now,
          same_site: cookie_settings[:same_site],
          secure: if cookie_settings[:secure].is_a?(Proc)
                        cookie_settings[:secure].call
                  else
                        cookie_settings[:secure]
                  end,
          httponly: cookie_settings[:httponly]
        }

        if remember_opt_in
            cookies.signed[:remember_opt_in] = {
              value: "1",
              expires: 30.days.from_now,
              same_site: :strict,
              secure: Rails.application.config.force_ssl,
              httponly: true
            }
        else
            cookies.delete(:remember_opt_in)
        end

        logger.info("[EEA Compliance] Consent accepted for user with IP: #{request.remote_ip}")

        return_to = session.delete(:return_to) || root_path

        respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(return_to) }
            format.html { redirect_to return_to }
        end
    end

    # POST /consent/decline
    def decline
        logger.warn("[EEA Compliance] Consent declined for user with IP: #{request.remote_ip}")

        html = <<~HTML
          <div class="consent-decline">
              <h1>Consent Required</h1>
              <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
              <button class="btn-secondary" data-action="click->consent#showScreen">Go Back</button>
          </div>
        HTML

        render turbo_stream: turbo_stream.morph(".consent-overlay", html)
    end

  private

    def rate_limit_consent_actions
        # Rate limit consent actions to prevent abuse (max 10 per minute)
        key = "consent_#{request.remote_ip}"
        current_count = Rails.cache.read(key) || 0

        if current_count >= 10
            render json: { error: "Too many consent requests" }, status: :too_many_requests
            return
        end

        Rails.cache.write(key, current_count + 1, expires_in: 1.minute)
    end
end
