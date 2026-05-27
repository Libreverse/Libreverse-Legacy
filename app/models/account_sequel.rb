# Primary Sequel-backed Account model (authoritative store). ActiveRecord `Account`
# exists only for libraries that require AR models.

require "sequel/model"
require_relative "../services/moderation_service"

# Stub ensures Zeitwerk's constant-naming contract is satisfied even when the
# Sequel connection is unavailable (e.g. during test boot before DB setup).
class AccountSequel; end

begin
  # Redefine as a full Sequel::Model once the connection is available.
  Object.send(:remove_const, :AccountSequel)
  class AccountSequel < Sequel::Model(:accounts)
    plugin :timestamps, update_on_create: true
    plugin :validation_helpers
    plugin :instance_hooks

    one_to_many :user_preferences, key: :account_id, dependent: :delete
    one_to_many :experiences, key: :account_id

    def validate
      super
      validate_username_moderation if username
    end

    def unverified? = status == 1
    def verified? = status == 2
    def closed? = status == 3
    def guest? = guest == true
    def system_account? = system_account == true
    def admin? = admin == true && !system_account?
    # Provide parity with ActiveRecord Account interface
    def effective_user? = !guest?

    # Some tests expect an email attribute. If column absent, expose nil (or derive later)
    def email
      values.key?(:email) ? self[:email] : nil
    end

    # Permissions mirrored for parity (Thredded uses AR Account, but keep here if reused)
    def thredded_can_read_messageboards = !guest?
    def thredded_can_write_messageboards = !guest?
    def thredded_can_message_users = !guest?
    def thredded_can_moderate_messageboards = admin?
    def thredded_admin? = admin?

    def before_create
      self.created_at ||= Time.zone.now if respond_to?(:created_at) && !created_at
      self.updated_at ||= Time.zone.now if respond_to?(:updated_at) && !updated_at
      super
    end

    def self.join_table_before_create(row)
      row[:created_at] ||= Time.zone.now if row.respond_to?(:created_at) && !row[:created_at]
      row[:updated_at] ||= Time.zone.now if row.respond_to?(:updated_at) && !row[:updated_at]
      row
    end

    private

    def validate_username_moderation
      return if username.blank?
      return unless ModerationService.contains_inappropriate_content?(username)

      violations = ModerationService.get_violation_details(username)
      log_moderation_violation("username", username, violations)
      errors.add(:username, "contains inappropriate content and cannot be saved")
    end

    def log_moderation_violation(field, _content, violations)
      violations ||= []
      reason = if violations.empty?
        "content flagged by comprehensive moderation system"
      else
        violations.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
      end
      Rails.logger.warn "Moderation violation in #{self.class.name} #{field}: #{reason}"
    rescue StandardError => e
      Rails.logger.error "Failed to log moderation violation: #{e.message}"
    end

    def federated_identifier
      if federated_id.present?
        "@#{federated_id}"
      else
        instance_domain = LibreverseInstance::Application.instance_domain
        "@#{username}@#{instance_domain}"
      end
    end

    def display_username = username

    def instance_domain
      if federated_id.present?
        federated_id.split("@").last
      else
        LibreverseInstance::Application.instance_domain
      end
    end

    def federated? = federated_id.present?
    def local? = !federated?
  end

  # Timestamp hooks for join table (mirror previous logic)
  Sequel::Model(:accounts_roles).define_method(:before_create) do
    self[:created_at] ||= Time.zone.now if respond_to?(:created_at) && !self[:created_at]
    self[:updated_at] ||= Time.zone.now if respond_to?(:updated_at) && !self[:updated_at]
    super()
  end
rescue StandardError => e
  warn "[AccountSequel] Skipped loading (#{e.class}: #{e.message})" if ENV["VERBOSE_BOOT"]
end
