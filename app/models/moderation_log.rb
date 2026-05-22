class ModerationLog < ApplicationRecord
  prepend MemoWise
  include GraphqlRails::Model

  graphql do |c|
    c.attribute(:id, type: "ID!")
    c.attribute(:field, type: "String!")
    c.attribute(:model_type, type: "String!")
    c.attribute(:content, type: "String!")
    c.attribute(:reason, type: "String!")
    c.attribute(:account_id, type: "ID")
    c.attribute(:violations, type: "[String]") # Parsed violations array
    c.attribute(:created_at, type: "String!")
  end

  belongs_to :account, optional: true

  validates :field, presence: true
  validates :model_type, presence: true
  validates :content, presence: true
  validates :reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_field, ->(field) { where(field: field) }
  scope :by_model, ->(model) { where(model_type: model) }
  scope :by_reason, ->(reason) { where(reason: reason) }

def self.log_rejection(field:, model_type:, content:, reason:, account: nil, violations: [])
    # Validate input parameters
    raise ArgumentError, "field cannot be blank" if field.blank?
    raise ArgumentError, "model_type cannot be blank" if model_type.blank?
    raise ArgumentError, "content cannot be blank" if content.blank?
    raise ArgumentError, "reason cannot be blank" if reason.blank?

     create!(
       field: field,
       model_type: model_type,
       content: content,
       reason: reason,
       account: account,
       violations_data: violations.to_json
     )
rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to log moderation rejection: #{e.message}"
    raise
end

memo_wise def violations
    return [] if violations_data.blank?
    return [] if violations_data.length > 1.megabyte

     JSON.parse(violations_data)
rescue JSON::ParserError
     []
end
end
