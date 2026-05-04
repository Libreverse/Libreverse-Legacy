require_relative "../services/moderation_service"

# ActiveRecord primary model (must always be defined for Zeitwerk autoloading)
class Account < ApplicationRecord
      has_many :account_roles, dependent: :destroy
      has_many :roles, through: :account_roles
      rolify
      self.table_name = "accounts"

      # Include Federails ActorEntity for ActivityPub federation (only in non-test environments)
      # Also check if the federails_actors table exists to avoid migration issues
      unless Rails.env.test?
        begin
          if ActiveRecord::Base.connection.table_exists?(:federails_actors)
            include Federails::ActorEntity

            # Configure field names for federation
            acts_as_federails_actor username_field: :username,
                                    name_field: :username,
                                    profile_url_method: :profile_url
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
          # Skip federails setup if database/table doesn't exist (e.g., during migrations)
        end
      end

      # Add ActiveRecord associations
      has_many :experiences, dependent: :destroy
      has_many :user_preferences, dependent: :destroy
      has_many :moderation_logs, dependent: :destroy

      # Content moderation validations
      validate :username_moderation

      # Callbacks for role assignment
      after_create :assign_default_role
      after_update :assign_default_role, if: :saved_change_to_guest?

      # Add any AR-specific logic or validations here if needed

      # Status helpers (matching Sequel model)
      def unverified?
        status == 1
      end

      def verified?
        status == 2
      end

      def closed?
        status == 3
      end

      # Check if this account is a guest account
      def guest?
        guest == true
      end

      # Determines if the account is an admin
      def admin?
        admin == true
      end

      # Role-based authentication helpers
      def authenticated_user?
        !guest?
      end

      def effective_user?
        authenticated_user? && !guest?
      end

      # Assign appropriate role based on guest status
      def assign_default_role
        if guest?
          add_role(:guest) unless has_role?(:guest)
        else
          add_role(:user) unless has_role?(:user)
          # Remove guest role if account is no longer a guest
          remove_role(:guest) if has_role?(:guest)
        end
      end

      def profile_url
        "https://#{LibreverseInstance::Application.instance_domain}/users/#{username}"
      end

      # Public method to ensure a federails actor exists for this account
      # Replaces the need to use send(:create_federails_actor)
      def ensure_federails_actor!
        return federails_actor if federails_actor.present?

        # Manually trigger actor creation by accessing the private method
        # This is the proper way to ensure actor creation
        send(:create_federails_actor)
        reload # Reload to get the newly created association
        federails_actor
      rescue StandardError => e
        Rails.logger.error "Failed to ensure federails actor for account #{id}: #{e.message}"
        raise e
      end

  private

      def username_moderation
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

        # Only log to Rails logger to avoid recursion since Account moderation
        # would trigger when creating ModerationLog records
        Rails.logger.warn "Moderation violation in #{self.class.name} #{field}: #{reason}"

        # NOTE: We don't log Account violations to database to avoid infinite recursion
        # since the ModerationLog belongs_to :account, which would trigger Account validation again
      rescue StandardError => e
        Rails.logger.error "Failed to log moderation violation: #{e.message}"
      end

      # ==> Federated Username Display Methods (matching Sequel model)

      # Returns the full federated identifier (@username@instance or @username@local)
      def federated_identifier
        if federated_id.present?
          # Already has a federated ID like "username@remote.instance"
          "@#{federated_id}"
        else
          # Local account - use local instance domain
          instance_domain = LibreverseInstance::Application.instance_domain
          "@#{username}@#{instance_domain}"
        end
      end

      # Returns just the username part without @ symbols
      def display_username
        username
      end

      # Returns the instance domain part
      def instance_domain
        if federated_id.present?
          # Extract domain from federated_id (format: username@domain)
          federated_id.split("@").last
        else
          # Local instance
          LibreverseInstance::Application.instance_domain
        end
      end

      # Check if this is a federated (remote) account
      def federated?
        federated_id.present?
      end

      # Check if this is a local account
      def local?
        !federated?
      end

  public # Ensure subsequent Thredded permission methods are public

      # ==> Thredded Permission Methods
      # These methods are required by Thredded for user permissions

      def thredded_can_read_messageboards
        if defined?(Thredded::Messageboard)
  Thredded::Messageboard.all
        else
  begin
                                                                          self.class.none
  rescue StandardError
                                                                          []
  end
        end
      end

      def thredded_can_write_messageboards
        if defined?(Thredded::Messageboard)
  Thredded::Messageboard.all
        else
  begin
                                                                          self.class.none
  rescue StandardError
                                                                          []
  end
        end
      end

      def thredded_can_message_users
        # Return a relation of users (accounts) allowed to be messaged; for now all non-guest accounts
        self.class.where(guest: false)
      end

      def thredded_can_moderate_messageboards
        return Thredded::Messageboard.none if defined?(Thredded::Messageboard) && !admin?

        if defined?(Thredded::Messageboard)
  Thredded::Messageboard.all
        else
  begin
                                                                          self.class.none
  rescue StandardError
                                                                          []
  end
        end
      end

      def thredded_admin?
        admin?
      end

      # Thredded class-level helpers for scoping
      def self.thredded_messageboards_readable_by(_user)
        if defined?(Thredded::Messageboard)
  Thredded::Messageboard.all
        else
  begin
                                                                          Thredded::Messageboard.none
  rescue StandardError
                                                                          []
  end
        end
      end

      def self.thredded_messageboards_writable_by(user)
        return thredded_messageboards_readable_by(user) unless defined?(Thredded::Messageboard)

        Thredded::Messageboard.all
      end

      def self.thredded_messageboards_moderatable_by(user)
        return Thredded::Messageboard.none unless defined?(Thredded::Messageboard)

        user&.admin? ? Thredded::Messageboard.all : Thredded::Messageboard.none
      end
end
