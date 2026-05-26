# frozen_string_literal: true

module GemfileLockPackages
  module_function

  def parse(content)
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
        gems["#{name}@#{version}"] = { name: name, version: version }
      elsif line =~ /^PLATFORMS/ || line =~ /^DEPENDENCIES/
        in_specs = false
      end
    end

    gems
  end

  def diff(head_content, base_content)
    head = parse(head_content)
    base = parse(base_content)
    head.reject { |key, _| base.key?(key) }.values
  end
end
