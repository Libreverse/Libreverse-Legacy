# Patch for Sequel direct inserts into account_active_session_keys

# Stub satisfies Zeitwerk's constant-naming contract when DB is unavailable at boot.
class AccountActiveSessionKey; end

if defined?(Sequel)
  begin
    Object.send(:remove_const, :AccountActiveSessionKey)
    class AccountActiveSessionKey < Sequel::Model(:account_active_session_keys)
      def before_create
        self.created_at ||= Time.zone.now if respond_to?(:created_at) && !created_at
        self.last_use ||= Time.zone.now if respond_to?(:last_use) && !last_use
        super
      end
    end
  rescue StandardError => e
    warn "[AccountActiveSessionKey] Skipped loading (#{e.class}: #{e.message})" if ENV["VERBOSE_BOOT"]
  end
end
