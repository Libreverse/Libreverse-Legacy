require "test_helper"

class WhitespaceCompressorTest < ActiveSupport::TestCase
  test "falls back to original html when minify_html raises" do
    app = lambda do |_env|
      [ 200, { "Content-Type" => "text/html; charset=utf-8" }, [ "<html><body><p>Hello</p></body></html>" ] ]
    end
    compressor = WhitespaceCompressor.new(app)

    compressor.define_singleton_method(:minify_html) do |_html, _config|
      raise StandardError, "native minifier panic"
    end

    status, headers, body = compressor.call({})

    assert_equal 200, status
    assert_equal "text/html; charset=utf-8", headers["Content-Type"]
    assert_includes body.join, "Hello"
  end

  test "skips minification for experience display pages" do
    original = "<html><body><iframe srcdoc=\"&lt;p&gt; keep &lt;/p&gt;\"></iframe></body></html>"
    app = lambda do |_env|
      [ 200, { "Content-Type" => "text/html; charset=utf-8" }, [ original ] ]
    end
    compressor = WhitespaceCompressor.new(app)

    compressor.define_singleton_method(:minify_html) do |_html, _config|
      flunk "minify_html should not run on display pages"
    end

    env = { "PATH_INFO" => "/experiences/my-slug/display" }
    status, _headers, body = compressor.call(env)

    assert_equal 200, status
    assert_equal original, body.join
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
    assert(configs.all? { |config| config[:minify_js] == false })
  end
end
