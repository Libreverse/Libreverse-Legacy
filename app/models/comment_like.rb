class CommentLike < ApplicationRecord
  belongs_to :comment
  counter_culture :comment, column_name: "likes_count"

  validates :account_id, presence: true
end
