# script/check_shareable_constants.rb
require_relative '../config/environment'

Rails.application.eager_load!

puts "Checking constants for shareability..."

app_root = Rails.root.to_s

def check_constants(mod, app_root, prefix = "", visited = Set.new)
  return if visited.include?(mod)

  visited.add(mod)

  mod.constants.sort.each do |const_name|
    next if const_name.to_s.start_with?('_') # Skip internal constants

    full_name = prefix.empty? ? const_name.to_s : "#{prefix}::#{const_name}"
    next if full_name.start_with?('ActionCable::') # Skip ActionCable to avoid pg dependency

    begin
      location = mod.const_source_location(const_name)
      next unless location&.first&.start_with?(app_root) # Only check constants defined in the app

      value = mod.const_get(const_name)

      if value.is_a?(Module)
        # Recurse into modules/classes
        check_constants(value, app_root, full_name, visited)
      else
        # Check shareability for non-module values
        begin
          puts "UNSHAREABLE: #{full_name} = #{value.inspect[0..100]}..." unless Ractor.shareable?(value)
        rescue Ractor::IsolationError => e
          puts "ISOLATION ERROR: #{full_name} - #{e.message}"
        end
      end
    rescue StandardError => e
      puts "Error checking #{full_name}: #{e.message}"
    end
  end
end

check_constants(Object, app_root, "", Set.new)

puts "Done."
