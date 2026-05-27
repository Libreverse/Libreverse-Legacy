# frozen_string_literal: true

# Internal ownership accounts for imports, indexing, and demo content.
# These are not credentials: they cannot sign in (no password, Rodauth blocks login)
# and never receive admin privileges.
class SystemAccounts
  METAVERSE_IMPORT_OWNER = "metaverse-system"
  DEMO_EXPERIENCES_OWNER = "admin_demo"
  DEV_METAVERSE_SEED_OWNER = "devseed"

  RESERVED_USERNAMES = [
    METAVERSE_IMPORT_OWNER,
    DEMO_EXPERIENCES_OWNER
  ].freeze

  class << self
    def find_or_create_metaverse_import_owner!
      find_or_create!(METAVERSE_IMPORT_OWNER)
    end

    def find_or_create_demo_experiences_owner!
      find_or_create!(DEMO_EXPERIENCES_OWNER)
    end

    def find_or_create_dev_metaverse_seed_owner!
      raise "dev seed account is only for development" unless Rails.env.development?

      find_or_create!(DEV_METAVERSE_SEED_OWNER, guest: true)
    end

    def find_or_create!(username, guest: false)
      unless RESERVED_USERNAMES.include?(username) ||
             (Rails.env.development? && username == DEV_METAVERSE_SEED_OWNER)
        raise ArgumentError, "unknown system account username: #{username}"
      end

      account = Account.find_by(username: username)
      return reconcile_existing!(account, guest: guest) if account

      Account.create!(
        username: username,
        status: 2, # verified
        admin: false,
        guest: guest,
        system_account: true,
        password_hash: nil
      )
    end

    def login_disabled?(account)
      account&.system_account?
    end

    private

    def reconcile_existing!(account, guest: false)
      updates = {}
      updates[:system_account] = true unless account.system_account?
      updates[:admin] = false if account.admin?
      updates[:guest] = guest if guest && !account.guest?
      updates[:password_hash] = nil if account.password_hash.present?

      account.update!(updates) if updates.any?
      account
    end
  end
end
