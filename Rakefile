# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

namespace :bundle do
  desc "Prune and enforce desired platforms (macOS arm/x86, Linux glibc arm64/x86_64, FreeBSD x86_64)"
  task enforce_platforms: :environment do
    desired = %w[arm64-darwin-23 x86_64-darwin-23 aarch64-linux-gnu x86_64-linux-gnu x86_64-freebsd]
    lock = 'Gemfile.lock'
    abort 'Gemfile.lock not found. Run bundle install first.' unless File.exist?(lock)
    platforms_section = false
    current = []
    File.readlines(lock).each do |line|
      if line.start_with?('PLATFORMS')
        platforms_section = true
        next
      end
      next unless platforms_section
      break if /^\S/.match?(line) # next section

        plat = line.strip
        next if plat.empty?

        current << plat
    end
    to_remove = current - desired
    to_add    = desired - current
    puts "Current platforms: #{current.join(', ')}"
    puts "Desired platforms: #{desired.join(', ')}"
    unless to_remove.empty?
      puts "Removing: #{to_remove.join(', ')}"
      system('bundle', 'lock', '--remove-platform', *to_remove) || abort('Failed to remove platforms')
    end
    unless to_add.empty?
      puts "Adding: #{to_add.join(', ')}"
      system('bundle', 'lock', '--add-platform', *to_add) || abort('Failed to add platforms')
    end
    puts 'Platform enforcement complete.'
  end

  desc "Check all gems are at least 1 week old (security gate)"
  task age_gate: :environment do
    system('ruby', 'scripts/gem-age-gate.rb') || exit(1)
  end
end
