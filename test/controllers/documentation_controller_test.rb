require "test_helper"

class DocumentationControllerTest < ActionDispatch::IntegrationTest
  test "docs index is public" do
    get documentation_path
    assert_response :success
    assert_match(/docsify-app|data-controller="docsify"/, response.body)
  end

  test "serves documentation markdown" do
    get documentation_content_path("README.md")
    assert_response :success
    assert_match(/markdown|text/, response.media_type.to_s)
    assert response.body.present?
  end

  test "serves sidebar markdown" do
    get documentation_content_path("_sidebar.md")
    assert_response :success
    assert_match(/Libreverse Documentation/, response.body)
  end

  test "rejects path traversal" do
    get documentation_content_path("%2e%2e/%2e%2e/Gemfile")
    assert_includes [404, 400], response.status
  end

  test "rejects missing file" do
    get documentation_content_path("no-such-file-xyz.md")
    assert_response :not_found
  end
end

