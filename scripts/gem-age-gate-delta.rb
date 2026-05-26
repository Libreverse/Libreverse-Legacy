#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'date'
require_relative 'lib/gemfile-lock-packages'

MIN_AGE_DAYS = Integer(ENV.fetch('MIN_AGE_DAYS', '7'))
MIN_AGE_SECONDS = MIN_AGE_DAYS * 24 * 60 * 60
CUTOFF_DATE = Time.now - MIN_AGE_SECONDS
BASE_REF = ENV.fetch('BASE_REF', 'origin/main')
ROOT = File.expand_path('..', __dir__)

RED = "\e[31m"
YELLOW = "\e[33m"
GREEN = "\e[32m"
RESET = "\e[0m"

def read_lock_at_ref(ref)
  out = `git -C #{ROOT} show #{ref}:Gemfile.lock 2>/dev/null`
  [$?.success?, out]
end

def get_publish_date(name, version)
  uri = URI("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  response = http.request(Net::HTTP::Get.new(uri))
  return nil unless response.code == '200'

  DateTime.parse(JSON.parse(response.body)['created_at']).to_time
rescue StandardError
  nil
end

puts "\n#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "#{GREEN}  🔒 GEM DELTA AGE GATE#{RESET}"
puts "#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "   Base ref: #{BASE_REF}"
puts "   Minimum age: #{MIN_AGE_DAYS} days\n"

head_content = File.read(File.join(ROOT, 'Gemfile.lock'))
ok, base_content = read_lock_at_ref(BASE_REF)
unless ok
  puts "#{YELLOW}⚠️  No base Gemfile.lock at #{BASE_REF}; treating all gems as new#{RESET}"
  base_content = "GEM\n  specs:\n"
end

added = GemfileLockPackages.diff(head_content, base_content)
if added.empty?
  puts "#{GREEN}✅ No new gems in lockfile delta.#{RESET}\n"
  exit 0
end

puts "   Checking #{added.length} new gem version(s)...\n"
recent = []
added.each_with_index do |g, i|
  published = get_publish_date(g[:name], g[:version])
  if published && published > CUTOFF_DATE
    recent << g.merge(published: published)
  end
  print "   #{i + 1}/#{added.length} checked...\r"
  $stdout.flush
  sleep 0.05
end
puts "\n"

if recent.any?
  puts "\n#{RED}❌ GEM DELTA AGE GATE BLOCKED#{RESET}"
  recent.each do |g|
    days = ((Time.now - g[:published]) / (24 * 60 * 60)).to_i
    puts "   #{RED}• #{g[:name]} (#{g[:version]})#{RESET} (#{days}d old)"
  end
  puts "\n#{YELLOW}   PR can stay open; re-run gates when versions age in.#{RESET}\n"
  exit 1
end

puts "#{GREEN}✅ All #{added.length} new gem version(s) meet #{MIN_AGE_DAYS}-day minimum age.#{RESET}\n"
exit 0
