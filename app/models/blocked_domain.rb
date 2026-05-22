# Model for tracking blocked federation domains
class BlockedDomain < ApplicationRecord
  second_level_cache expires_in: 1.week
  before_validation { self.domain = domain&.downcase }
  validates :domain,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9.-]+\z/, message: "invalid domain" }
  validates :blocked_at, presence: true

  scope :recent, -> { order(blocked_at: :desc) }

  def self.blocked?(domain)
    exists?(domain: domain)
  end
end
