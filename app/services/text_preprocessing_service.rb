class TextPreprocessingService
  # Common English stop words
  STOP_WORDS = %w[
    a am an and are as at be been being by can could did do does for from get gets getting
    got going had has have he her hers herself him himself his i in is it its itself
    may me might must my myself of on our ours ourselves shall she should that the
    their theirs them themselves these they this those to was were will with would
    you your yours yourself yourselves
  ].to_set.freeze

  # Punctuation and special characters to remove
  PUNCTUATION_REGEX = /[^\w\s]/

  class << self
    # Main preprocessing pipeline
    def preprocess(text)
      return [] if text.blank?

      # Normalize text
      normalized = normalize_text(text)

      # Tokenize into words
      words = tokenize(normalized)

      # Remove stop words
      filtered_words = remove_stop_words(words)

      # Generate n-grams
      word_ngrams = generate_word_ngrams(filtered_words, 2)
      char_ngrams = generate_char_ngrams(normalized, 3)

      # Combine all features
      (filtered_words + word_ngrams + char_ngrams).uniq
    end

    # Normalize text (lowercase, remove punctuation, etc.)
    def normalize_text(text)
      text.downcase.gsub(PUNCTUATION_REGEX, " ").strip
    end

    # Split text into words
    def tokenize(text)
      text.split(/\s+/).reject(&:empty?)
    end

    # Remove common stop words
    def remove_stop_words(words)
      words.reject { |word| STOP_WORDS.include?(word) || word.length < 2 }
    end

    # Generate word n-grams
    def generate_word_ngrams(words, ngram_size)
      return [] if words.length < ngram_size

      words.each_cons(ngram_size).map { |ngram| ngram.join("_") }
    end

    # Generate character n-grams
    def generate_char_ngrams(text, ngram_size)
      return [] if text.length < ngram_size

      # Add padding for beginning and end of text
      padded_text = "#{'_' * (ngram_size - 1)}#{text.gsub(/\s+/, '_')}#{'_' * (ngram_size - 1)}"

      (0..padded_text.length - ngram_size).map do |i|
        "char_#{padded_text[i, ngram_size]}"
      end
    end

    # Extract all unique terms from a collection of experiences
    def extract_vocabulary(experiences)
      vocabulary = Set.new

      experiences.find_each do |experience|
        content = combine_experience_text(experience)
        terms = preprocess(content)
        vocabulary.merge(terms)
      end

      vocabulary.to_a.sort
    end

    # Combine all searchable text from an experience
    def combine_experience_text(experience)
      [
        experience.title,
        experience.description,
        experience.author
      ].compact.join(" ")
    end
  end
end
