require "active_storage_validations"

class Experience < ApplicationRecord
  second_level_cache expires_in: 1.week
  extend FriendlyId
  include ActiveStorageValidations::Model
  include GraphqlRails::Model
  include FederatableExperience
  include EncodingNormalizer

  graphql do |c|
    c.attribute(:id, type: "ID!")
    c.attribute(:title, type: "String!")
    c.attribute(:description, type: "String")
    c.attribute(:author, type: "String")
    c.attribute(:approved, type: "Boolean!")
    c.attribute(:account_id, type: "ID")
    c.attribute(:html_file?, type: "Boolean!")
    c.attribute(:federate, type: "Boolean!")
    c.attribute(:offline_available, type: "Boolean!")
    c.attribute(:created_at, type: "String!")
    c.attribute(:updated_at, type: "String!")
  end

  belongs_to :account, optional: true
  has_one :experience_vector, dependent: :destroy
  has_one_attached :html_file, dependent: :purge_later
  encrypts_attached :html_file

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validates :author, length: { maximum: 255 }
  validates :federate, inclusion: { in: [ true, false ] }
  validates :offline_available, inclusion: { in: [ true, false ] }
  validates :html_file, presence: true,
                        content_type: "text/html",
                        size: { less_than: 5.megabytes, message: "must be less than 5MB" },
                        filename: {
                          with: /\A[\w.-]+\z/,
                          message: "only letters, numbers, underscores, dashes and periods are allowed in filenames"
                        }, unless: -> { Rails.env.test? }

  # Content moderation validation
  validate :content_moderation

  # Force UTF-8 encoding prior to other validations (defensive for binary fixtures)
  before_validation :force_utf8_encoding, prepend: true
  # Normalize encoding for user-provided textual fields to avoid transliteration errors
  normalize_encoding_for :title, :description, :author

  # Ensure an owner is always associated
  before_validation :assign_owner, on: :create

  # Add a scope for approved experiences
  scope :approved, -> { where(approved: true) }

  # Add a scope for experiences pending approval
  scope :pending_approval, -> { where(approved: false) }

  # Add a scope for experiences configured to federate
  scope :federating, -> { where(federate: true) }

  # Add a scope for offline-available experiences
  scope :offline_available, -> { where(offline_available: true) }

  # Add a scope for online-only experiences
  scope :online_only, -> { where(offline_available: false) }

  # Automatically mark experiences created by admins as approved
  before_validation :auto_approve_for_admin, on: :create

  # Schedule vectorization after creation and updates
  # Only trigger if key attributes changed or it's a new record to avoid redundant job enqueues
  after_commit :schedule_vectorization, on: %i[create update], if: :should_vectorize?

  friendly_id :slug_candidates, use: %i[slugged finders history]

  def assign_owner
    # Use Current.account set by Reflex or fallback to Rodauth
    self.account_id ||= Current.account&.id || nil
  end

  def auto_approve_for_admin
    self.approved = true if account&.admin?
  end

  def html_file?
    html_file.attached?
  end

  def slug_candidates
    [
      :title,
      [ :title, SecureRandom.hex(3) ]
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_title?
  end

  # Check if this experience needs vectorization
  def needs_vectorization?
    # Vectorize ALL experiences, regardless of approval status
    # This allows for better search and admin/moderator functionality

    # No vector exists
    return true unless experience_vector

    # Vector is outdated
    experience_vector.needs_regeneration?(self)
  end

  # Find similar experiences using vector search
  def find_similar(limit: 10)
    ExperienceSearchService.find_related(self, limit: limit)
  end

  private

  def content_moderation
    # Check if automoderation is enabled instance-wide (default to true for security)
    automoderation_enabled = InstanceSetting.get_with_fallback("automoderation_enabled", nil, "true") == "true"

    # Skip moderation if disabled by admin
    return unless automoderation_enabled

    violations_found = false
    all_violations = []

    # Check title
    if title.present?
      title_violations = ModerationService.get_violation_details(title)
      if title_violations.present?
        all_violations << { field: "title", content: title, violations: title_violations }
        errors.add(:title, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Check description
    if description.present?
      description_violations = ModerationService.get_violation_details(description)
      if description_violations.present?
        all_violations << { field: "description", content: description, violations: description_violations }
        errors.add(:description, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Check author
    if author.present?
      author_violations = ModerationService.get_violation_details(author)
      if author_violations.present?
        all_violations << { field: "author", content: author, violations: author_violations }
        errors.add(:author, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Log a single violation entry if any violations were found
    return unless violations_found

    log_moderation_violations(all_violations)
  end

  def log_moderation_violations(all_violations)
    # Use the first violation's field and content for the primary log entry
    primary_violation = all_violations.first

    # Combine all violation details
    all_violation_details = all_violations.flat_map { |v| v[:violations] || [] }

    # Create a comprehensive reason
    reason = if all_violation_details.empty?
      "content flagged by comprehensive moderation system"
    else
      all_violation_details.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
    end

    ModerationLog.log_rejection(
      field: primary_violation[:field],
      model_type: self.class.name,
      content: primary_violation[:content],
      reason: reason,
      account: account || Current.account,
      violations: all_violation_details
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log moderation violation: #{e.message}"
  end

  # Determine if this experience should be vectorized
  def should_vectorize?
    # Vectorize ALL experiences for comprehensive search functionality

    # No vector exists - always needs vectorization
    return true unless experience_vector

    # Check if content has changed since last vectorization using persisted attributes
    # This works in async jobs unlike saved_change_to_*? methods
    experience_vector.needs_regeneration?(self)
  end

  # Schedule vectorization job
  def schedule_vectorization
    if Rails.env.development?
      # Run synchronously in development for immediate vector search
      VectorizeExperienceJob.perform_now(id)
    else
      # Run asynchronously in production
      VectorizeExperienceJob.perform_later(id)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to schedule vectorization for experience #{id}: #{e.message}"
  end

  def force_utf8_encoding
    %i[title description author].each do |attr|
      val = self[attr]
      next unless val.is_a?(String)

      next if val.encoding == Encoding::UTF_8 && val.valid_encoding?

      begin
        coerced = val.dup.force_encoding(Encoding::UTF_8)
        coerced = coerced.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "") unless coerced.valid_encoding?
        self[attr] = coerced
      rescue StandardError
        self[attr] = val.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
      end
    end
  end
end
