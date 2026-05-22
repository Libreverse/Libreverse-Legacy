class IndexedContent < ApplicationRecord
  prepend MemoWise
  # Associations
  has_one :indexed_content_vector, dependent: :destroy

  # JSON serialization for TiDB compatibility (MySQL-compatible distributed database)
  serialize :metadata, coder: JSON
  serialize :coordinates, coder: JSON

  # Validations
  validates :source_platform, presence: true
  validates :external_id, presence: true
  validates :content_type, presence: true
  validates :external_id, uniqueness: { scope: :source_platform }

  # Scopes
  scope :by_platform, ->(platform) { where(source_platform: platform) }
  scope :by_content_type, ->(type) { where(content_type: type) }
  scope :recently_indexed, -> { where("last_indexed_at > ?", 24.hours.ago) }
  scope :needs_update, -> { where("last_indexed_at < ? OR last_indexed_at IS NULL", 24.hours.ago) }

  # Callbacks
  after_commit :schedule_vectorization, on: %i[create update], if: :should_vectorize?

  # Class methods
  def self.platforms
    distinct.pluck(:source_platform).sort
  end

  def self.content_types
    distinct.pluck(:content_type).sort
  end

  # Instance methods
  def platform_display_name
    source_platform.humanize
  end

  def needs_update?
    last_indexed_at.nil? || last_indexed_at < 24.hours.ago
  end

  memo_wise def coordinates_hash
    coordinates.is_a?(Hash) ? coordinates : {}
  end

  memo_wise def metadata_hash
    metadata.is_a?(Hash) ? metadata : {}
  end

  # For search integration
  def to_unified_content
    UnifiedIndexedContent.new(self)
  end

  # Check if this indexed content needs vectorization
  def needs_vectorization?
    # No vector exists
    return true unless indexed_content_vector

    # Vector is outdated
    indexed_content_vector.needs_regeneration?(self)
  end

  # Find similar content using vector search
  def find_similar(limit: 10)
    IndexedContentSearchService.find_related(self, limit: limit)
  end

  # Determine if this content should be vectorized
  def should_vectorize?
    # No vector exists - always needs vectorization
    return true unless indexed_content_vector

    # Check if content has changed since last vectorization
    indexed_content_vector.needs_regeneration?(self)
  end

  # Schedule vectorization job
  def schedule_vectorization
    if Rails.env.development?
      # Run synchronously in development for immediate vector search
      VectorizeIndexedContentJob.perform_now(id)
    else
      # Run asynchronously in production
      VectorizeIndexedContentJob.perform_later(id)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to schedule vectorization for indexed_content #{id}: #{e.message}"
  end
end
