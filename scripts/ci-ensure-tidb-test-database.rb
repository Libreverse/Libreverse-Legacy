#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "trilogy"

database = ENV.fetch("TIDB_TEST_DATABASE", "libreverse_test")
raise "Invalid test database name: #{database.inspect}" unless database.match?(/\A[a-zA-Z0-9_]+\z/)

ssl_mode_name = ENV.fetch("TIDB_TEST_SSL_MODE", ENV.fetch("TIDB_SSL_MODE", "VERIFY_IDENTITY")).upcase
ssl_mode = case ssl_mode_name
           when "DISABLED" then Trilogy::SSL_DISABLED
           when "PREFERRED" then Trilogy::SSL_PREFERRED_NOVERIFY
           when "REQUIRED" then Trilogy::SSL_REQUIRED_NOVERIFY
           when "VERIFY_CA" then Trilogy::SSL_VERIFY_CA
           when "VERIFY_IDENTITY" then Trilogy::SSL_VERIFY_IDENTITY
           else
             raise "Unsupported TIDB test SSL mode: #{ssl_mode_name}"
           end

ssl_ca = RUBY_PLATFORM.match?(/darwin/) ? "/etc/ssl/cert.pem" : "/etc/ssl/certs/ca-certificates.crt"

conn = Trilogy.new(
  host: ENV.fetch("TIDB_HOST"),
  username: ENV.fetch("TIDB_USERNAME"),
  password: ENV.fetch("TIDB_PASSWORD"),
  port: 4000,
  ssl_mode: ssl_mode,
  ssl_ca: ssl_ca
)

conn.query(
  "CREATE DATABASE IF NOT EXISTS `#{database}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
)
puts "Ensured TiDB test database #{database} exists"
