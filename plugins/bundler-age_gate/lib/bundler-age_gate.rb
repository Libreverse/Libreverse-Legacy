# frozen_string_literal: true

require 'bundler/plugin/api'

Bundler::Plugin::API.hook('before-install-all') do |_dependencies|
  next if ENV['BUNDLER_AGE_GATE_RAN'] == '1'

  ENV['BUNDLER_AGE_GATE_RAN'] = '1'
  unless system('ruby', 'scripts/gem-age-gate.rb')
    abort 'Gem age gate failed - bundle install blocked'
  end
end
