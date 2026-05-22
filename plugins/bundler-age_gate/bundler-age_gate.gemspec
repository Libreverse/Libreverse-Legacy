# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'bundler-age_gate'
  s.version = '1.0.0'
  s.summary = 'Enforces minimum gem age for security'
  s.description = 'Bundler plugin that blocks install if gems are newer than 7 days'
  s.authors = [ 'Security' ]
  s.files = [ 'plugins.rb', 'lib/bundler-age_gate.rb' ]
  s.require_paths = [ 'lib' ]
end
