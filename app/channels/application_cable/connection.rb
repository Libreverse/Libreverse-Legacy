module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identify the connection by the authenticated account ID found in the session
    identified_by :current_account_id

    # P2P connection tracking
    attr_accessor :peer_id, :session_id, :connected_at

    def connect
      Rails.logger.debug "[ActionCable] Attempting to establish connection..."

      # Store connection timestamp for P2P
      self.connected_at = Time.current

      # Trust rodauth / rodauth-guest to manage session state (real user or guest)
      # RodauthApp middleware should have already ensured a session exists.
      self.current_account_id = find_account_id_from_session

      # Reject if no identification was possible via session
      unless current_account_id
        Rails.logger.warn "[ActionCable] Rejecting connection: No authenticated user or guest found in session."
        reject_unauthorized_connection
        return # Ensure connect method exits after rejection
      end

      # Log successful connection identified via session
      # Handle invalid session markers (negative account IDs)
      begin
      if current_account_id&.negative?
        Rails.logger.info "[ActionCable] Connection established with invalid session marker: #{current_account_id}"
        # Reject connection so the client can clear cookies
        reject_unauthorized_connection
        return
      end

      account = AccountSequel.with_pk!(current_account_id)
        account_type = account.guest? ? "guest" : "user"
        Rails.logger.info "[ActionCable] Connection established for \\#{account_type} account_id: \\#{current_account_id}"
      rescue Sequel::NoMatchingRow
         Rails.logger.error "[ActionCable] Connection established but Account record not found for ID: \\#{current_account_id}"
         reject_unauthorized_connection # Reject if account doesn't exist
      end
    end

    private

    # Finds a valid account ID (real or guest) from the session store (expecting CookieStore)
    def find_account_id_from_session
      session_key = Rails.application.config.session_options[:key]
      Rails.logger.debug "[ActionCable][CookieStore] Attempting to find session using key: #{session_key}"

      session_data =
        begin
          # For CookieStore, the entire session hash is in the cookie.
          # Try encrypted first, then signed as fallback.
          Rails.logger.debug "[ActionCable][CookieStore] Trying cookies.encrypted..."
          data = cookies.encrypted[session_key]
          Rails.logger.debug "[ActionCable][CookieStore] Result from cookies.encrypted: #{data.inspect}"

          unless data.is_a?(Hash)
            Rails.logger.debug "[ActionCable][CookieStore] Trying cookies.signed as fallback..."
            data = cookies.signed[session_key]
            Rails.logger.debug "[ActionCable][CookieStore] Result from cookies.signed (fallback): #{data.inspect}"
          end
          data
        rescue StandardError => e
          Rails.logger.error "[ActionCable][CookieStore] Error accessing/verifying session cookie: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          return nil
        end

      unless session_data.is_a?(Hash)
        Rails.logger.warn "[ActionCable][CookieStore] Could not retrieve session hash from cookie ('#{session_key}'). Data: #{session_data.inspect}"
        return nil
      end

      # --- Extract account_id directly from the session hash ---
      rodauth_session_key_name = :account_id # Default Rodauth key name (symbol)
      rodauth_session_key_string = rodauth_session_key_name.to_s # String version
      account_id =
        begin
          # Try to get the configured key name safely if Rodauth instance available
          # Note: request.env['rodauth'] is likely nil here, so fallback usually runs
          rodauth_instance = request.env["rodauth"]
          if rodauth_instance.respond_to?(:session_key)
            config_key = rodauth_instance.session_key
            rodauth_session_key_name = config_key if config_key.is_a?(Symbol)
            rodauth_session_key_string = config_key.to_s
          end

          # Check for string key first (seems to be what CookieStore provides),
          # then symbol key fallback.
          session_data[rodauth_session_key_string] || session_data[rodauth_session_key_name]
        rescue StandardError => e
          Rails.logger.warn "[ActionCable][CookieStore] Error getting rodauth session key, falling back to default :account_id. Error: #{e.message}"
          # Fallback access trying both string and symbol
          session_data["account_id"] || session_data[:account_id]
        end
      # -------------------------------------------------------

      if account_id
         Rails.logger.debug "[ActionCable][CookieStore] Found account_id '#{account_id}' in session data using key '#{rodauth_session_key_string}'"
         verified_account = AccountSequel.where(id: account_id).first
         unless verified_account
            Rails.logger.warn "[ActionCable][CookieStore] Account ID '\\#{account_id}' found in session does not exist in DB. Ignoring."
            return nil
         end
         account_id # Return the verified ID
      else
         Rails.logger.debug "[ActionCable][CookieStore] No account_id found in session data using key '#{rodauth_session_key_string}'"
         nil
      end
    rescue StandardError => e
      Rails.logger.error "[ActionCable][CookieStore] Error during session processing: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    # --- REMOVED create_guest_account ---
    # --- REMOVED allow_guest_connections? ---
  end
end
