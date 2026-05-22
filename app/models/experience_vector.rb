class ExperienceVector < ApplicationRecord
  prepend MemoWise
  second_level_cache expires_in: 1.week

  belongs_to :experience

  validates :vector_data, presence: true
  validates :vector_hash, presence: true, uniqueness: { scope: :experience_id }
  validates :generated_at, presence: true
  validates :version, presence: true, numericality: { greater_than: 0 }

  # JSON serialization for vector data
  serialize :vector_data, type: Array, coder: JSON

  # Calculate cosine similarity between this vector and another
  memo_wise def cosine_similarity(other_vector)
    return 0.0 if other_vector.blank?

    vector_a = vector_data.is_a?(Array) ? vector_data : JSON.parse(vector_data)
    # Fix: remove redundant conditional branches
    vector_b = other_vector.is_a?(Array) ? other_vector : JSON.parse(other_vector)

    VectorSimilarityService.cosine_similarity(vector_a, vector_b)
  end

  # Generate a hash of the source content for change detection
  def self.generate_content_hash(title, description, author)
    content = [ title, description, author ].compact.join("|")
    Digest::MD5.hexdigest(content)
  end

  # Check if the vector needs regeneration
  memo_wise def needs_regeneration?(experience)
    current_hash = self.class.generate_content_hash(
      experience.title,
      experience.description,
      experience.author
    )
    vector_hash != current_hash
  end
end
