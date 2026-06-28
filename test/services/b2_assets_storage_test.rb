# frozen_string_literal: true

require "test_helper"

class B2AssetsStorageTest < ActiveSupport::TestCase
  setup do
    @vite_root = Rails.root.join("tmp/vite_b2_test/public/vite")
    FileUtils.rm_rf(@vite_root.parent)
    @vite_root.join(".vite").mkpath
    @vite_root.join("assets").mkpath
    @manifest = @vite_root.join(".vite/manifest.json")
    @asset = @vite_root.join("assets/application-abc123.js")
    @manifest.write('{"entries":{}}')
    @asset.write("bundle")
  end

  teardown do
    FileUtils.rm_rf(Rails.root.join("tmp/vite_b2_test"))
  end

  test "strip_from_image keeps manifest files and removes other vite output" do
    B2AssetsStorage.strip_from_image!(root: @vite_root)

    assert @manifest.exist?
    assert_not @asset.exist?
  end

  test "strip_from_image keeps css for same-origin url() resolution" do
    stylesheet = @vite_root.join("assets/application-abc123.css")
    stylesheet.write("body{color:red}")

    B2AssetsStorage.strip_from_image!(root: @vite_root)

    assert stylesheet.exist?
    assert_not @asset.exist?
  end

  test "keep_in_image? retains manifests and css" do
    assert B2AssetsStorage.keep_in_image?(".vite/manifest.json")
    assert B2AssetsStorage.keep_in_image?("assets/application-abc123.css")
    assert_not B2AssetsStorage.keep_in_image?("assets/application-abc.js")
  end

  test "public_object_url points at the B2 friendly CDN host" do
    assert_equal(
      "https://libreverse-legacy-static.libreverse.io/file/libreverse-legacy-assets/vite/assets/application-abc123.js",
      B2AssetsStorage.public_object_url("assets/application-abc123.js")
    )
  end

  test "cdn_url_for_manifest_path maps /vite paths to CDN URLs when enabled" do
    B2AssetsStorage.stub(:cdn_urls?, true) do
      assert_equal(
        "https://libreverse-legacy-static.libreverse.io/file/libreverse-legacy-assets/vite/assets/application-abc123.js",
        B2AssetsStorage.cdn_url_for_manifest_path("/vite/assets/application-abc123.js")
      )
    end
  end

  test "cdn_url_for_manifest_path leaves paths unchanged when CDN is disabled" do
    assert_equal(
      "/vite/assets/application-abc123.js",
      B2AssetsStorage.cdn_url_for_manifest_path("/vite/assets/application-abc123.js")
    )
  end

  test "configured? is false without credentials" do
    original_key = ENV["B2_ASSETS_KEY_ID"]
    original_secret = ENV["B2_ASSETS_SECRET"]
    ENV.delete("B2_ASSETS_KEY_ID")
    ENV.delete("B2_ASSETS_SECRET")

    assert_not B2AssetsStorage.configured?
  ensure
    if original_key.nil?
      ENV.delete("B2_ASSETS_KEY_ID")
    else
      ENV["B2_ASSETS_KEY_ID"] = original_key
    end
    if original_secret.nil?
      ENV.delete("B2_ASSETS_SECRET")
    else
      ENV["B2_ASSETS_SECRET"] = original_secret
    end
  end
end
