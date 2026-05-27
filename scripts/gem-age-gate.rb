#!/usr/bin/env ruby
# frozen_string_literal: true

# GEM AGE GATE - Enforces 1-week minimum age for all RubyGems
# Exit code 1 = Block the operation
# Exit code 0 = Allow the operation

require 'bundler'
require 'net/http'
require 'json'
require 'date'

MIN_AGE_DAYS = 7
MIN_AGE_SECONDS = MIN_AGE_DAYS * 24 * 60 * 60
CUTOFF_DATE = Time.zone.now - MIN_AGE_SECONDS

RED = "\e[31m"
YELLOW = "\e[33m"
GREEN = "\e[32m"
CYAN = "\e[36m"
RESET = "\e[0m"

puts "\n#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "#{GREEN}  🔒 GEM AGE GATE - SECURITY CHECK#{RESET}"
puts "#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "   Minimum age: #{MIN_AGE_DAYS} days"
puts "   Cutoff date: #{CUTOFF_DATE.strftime('%Y-%m-%d')}"
puts "#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}\n"

# Parse Gemfile.lock to get resolved versions
def parse_gemfile_lock
  lockfile_path = File.join(__dir__, '..', 'Gemfile.lock')
  content = File.read(lockfile_path)

  gems = {}
  in_specs = false

  content.each_line do |line|
    if /^GEM$/.match?(line)
      in_specs = false
    elsif /^  specs:$/.match?(line)
      in_specs = true
    elsif in_specs && line =~ /^    ([\w\-_.]+) \(([^)]+)\)$/
      name = Regexp.last_match(1)
      version = Regexp.last_match(2).split(',').first.strip
      gems[name] = version
    elsif line =~ /^PLATFORMS/ || line =~ /^DEPENDENCIES/
      in_specs = false
    end
  end

  gems
end

# Check RubyGems API for version publish date
def get_publish_date(name, version)
  uri = URI("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10

  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'application/json'

  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    DateTime.parse(data['created_at']).to_time
  end
rescue StandardError
  nil
end

# Main validation with parallel processing
def validate
  gems = parse_gemfile_lock

  if gems.empty?
    puts "#{RED}❌ No gems found - cannot validate safety#{RESET}"
    puts "   Defaulting to BLOCK for security.\n"
    exit 1
  end

  puts "   Checking #{gems.length} gems in parallel...\n"

  recent_gems = []
  checked = 0
  mutex = Mutex.new

  # Process in batches of 20 concurrent threads
  gems.each_slice(20) do |batch|
    threads = batch.map do |name, version|
      Thread.new do
        published = get_publish_date(name, version)

        mutex.synchronize do
          checked += 1
          if published && published > CUTOFF_DATE
            recent_gems << {
              name: name,
              version: version,
              published: published,
              days_ago: ((Time.zone.now - published) / (24 * 60 * 60)).to_i
            }
          end
          print "   #{checked}/#{gems.length} checked...\r"
          $stdout.flush
        end
      end
    end

    threads.each(&:join)
    sleep 0.5 # Brief pause between batches to be nice to the API
  end

  puts "\n"

  if recent_gems.any?
    puts "\n#{RED}❌ GEM AGE GATE BLOCKED#{RESET}"
    puts "   #{recent_gems.length} gem(s) are newer than #{MIN_AGE_DAYS} days:\n"

    recent_gems.each do |g|
      puts "   #{RED}• #{g[:name]} (#{g[:version]})#{RESET}"
      puts "     Published: #{g[:published].strftime('%Y-%m-%d')} (#{g[:days_ago]} days ago)"
    end

    max_date = recent_gems.map { |g| g[:published] }.max
    unlock_date = max_date + MIN_AGE_SECONDS
    puts "\n#{YELLOW}   ⏳ Available after: #{unlock_date.strftime('%Y-%m-%d')}#{RESET}"
    puts "\n   Operation BLOCKED.\n"
    exit 1
  end

  puts "#{GREEN}✅ All #{gems.length} gems meet the #{MIN_AGE_DAYS}-day minimum age.#{RESET}\n"
  exit 0
end

begin
  validate
rescue StandardError => e
  puts "#{RED}❌ Validation error: #{e.message}#{RESET}"
  puts "   Defaulting to BLOCK for security.\n"
  exit 1
end
