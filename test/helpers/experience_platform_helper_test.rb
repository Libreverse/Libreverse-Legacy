# frozen_string_literal: true

require "test_helper"

class ExperiencePlatformHelperTest < ActionView::TestCase
  include ExperiencePlatformHelper

  test "prepare_experience_html injects platform and utility scripts" do
    html = prepare_experience_html("<html><head></head><body><p>hi</p></body></html>")

    assert_includes html, "Libreverse.services.multiplayer"
    assert_includes html, "requestStorageAccessIfNeeded"
    assert_includes html, "requestPermissionsIfNeeded"
    assert_includes html, "__LIBREVERSE_COLLAB_SCRIPT_URL__"
    assert_operator html.scan("<script>").length, :>=, 5
  end

  test "prepare_experience_html wraps html fragments in a document shell" do
    html = prepare_experience_html("<p>fragment</p>")

    assert_includes html, "<html>"
    assert_includes html, "<head>"
    assert_includes html, "<body><p>fragment</p></body>"
    assert_includes html, "Libreverse.services.multiplayer"
  end
end
