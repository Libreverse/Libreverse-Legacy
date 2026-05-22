# frozen_string_literal: true

require "oj"

# Replace the stdlib JSON module with Oj's faster implementation.
# mimic_JSON patches JSON.parse, JSON.generate, JSON.dump, JSON.load, etc.
Oj.mimic_JSON

# Patch ActiveSupport::JSON (used by AR encryption, to_json on AR models, etc.)
# so that ActiveSupport's encode/decode path also goes through Oj.
Oj.optimize_rails
