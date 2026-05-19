require "test_helper"

class WhitespaceCompressorTest < ActiveSupport::TestCase
  test "falls back to original html when minify_html raises" do
    app = lambda do |_env|
      [ 200, { "Content-Type" => "text/html; charset=utf-8" }, [ "<html><body><p>Hello</p></body></html>" ] ]
    end
    compressor = WhitespaceCompressor.new(app)

    compressor.define_singleton_method(:minify_html) do |_html, _config|
      raise Exception, "native minifier panic"
    end

    status, headers, body = compressor.call({})

    assert_equal 200, status
    assert_equal "text/html; charset=utf-8", headers["Content-Type"]
    assert_includes body.join, "Hello"
  end

  test "does not enable js minification for iframe srcdoc" do
    compressor = WhitespaceCompressor.new(->(_env) { [ 200, { "Content-Type" => "text/plain" }, [] ] })
    configs = []

    compressor.define_singleton_method(:minify_html) do |html, config|
      configs << config
      html
    end

    compressor.minify_srcdoc_iframes_with_nokogiri('<html><body><iframe srcdoc="&lt;script&gt;if (a) { return b } else { return c }&lt;/script&gt;"></iframe></body></html>')

    assert configs.any?
    assert configs.all? { |config| config[:minify_js] == false }
  end
end
