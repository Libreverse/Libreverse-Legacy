class Comment < ApplicationRecord
  belongs_to :thread, class_name: "CommentThread", foreign_key: :comment_thread_id, counter_cache: true, inverse_of: :comments
  begin
    belongs_to :account, class_name: "Account", optional: false, inverse_of: false
  rescue StandardError
    nil
  end
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :children, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent, fully_load: true
  has_many :likes, class_name: "CommentLike", dependent: :destroy

  scope :root, -> { where(parent_id: nil) }
  scope :visible, -> { where(deleted_at: nil) }
  scope :ordered_by_likes, -> { order(likes_count: :desc, created_at: :asc) }

  validates :body, presence: true, length: { maximum: 10_000 }
  validates :moderation_state, inclusion: { in: %w[pending rejected approved] }

  before_validation :ensure_defaults, :extract_mentions
  before_validation :set_initial_moderation_state

  def extract_mentions
    usernames = body.to_s.scan(/@([A-Za-z0-9_]{3,30})/).flatten.uniq
    return if usernames.empty?

    ids = AccountSequel.where(username: usernames).select_map(:id)
    self.mentions_cache = ids
  end

  def ensure_defaults
    self.mentions_cache ||= []
  end

  def set_initial_moderation_state
    self.moderation_state ||= "pending"
  end

  def approved?
    moderation_state == "approved"
  end

  def reject!(reason: nil)
    update!(moderation_state: "rejected", moderation_flags: { reason: reason, at: Time.current })
  end

  def approve!(approver: nil)
    update!(moderation_state: "approved", approved_at: Time.current, approved_by_id: approver&.id)
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
