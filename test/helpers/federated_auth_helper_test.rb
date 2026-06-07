require "test_helper"

class FederatedAuthHelperTest < ActionView::TestCase
  include FederatedAuthHelper

  test "register_dynamic_client rejects endpoint on a different host" do
    HTTParty.expects(:post).never

    result = register_dynamic_client(
      "https://evil.example/register",
      "https://app.example/auth/callback",
      oidc_domain: "trusted.example",
    )

    assert_equal({ error: "Invalid registration endpoint" }, result)
  end

  test "register_dynamic_client rejects private network hosts" do
    HTTParty.expects(:post).never

    result = register_dynamic_client(
      "https://192.168.1.1/register",
      "https://app.example/auth/callback",
      oidc_domain: "192.168.1.1",
    )

    assert_equal({ error: "Invalid registration endpoint" }, result)
  end

  test "register_dynamic_client posts to sanitized endpoint on matching domain" do
    endpoint = "https://trusted.example/oauth/register"
    mock_response = stub(success?: true, body: { client_id: "abc" }.to_json)

    HTTParty.expects(:post).with(
      endpoint,
      has_entries(body: kind_of(String), timeout: 10),
    ).returns(mock_response)

    result = register_dynamic_client(
      endpoint,
      "https://app.example/auth/callback",
      oidc_domain: "trusted.example",
    )

    assert_equal({ "client_id" => "abc" }, result)
  end

  test "parse_identifier enforces minimum username length" do
    assert_equal [ nil, nil ], parse_identifier("ab@trusted.example")
    assert_equal [ "alice", "trusted.example" ], parse_identifier("alice@trusted.example")
  end
end
