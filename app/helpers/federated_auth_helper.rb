module FederatedAuthHelper
  def parse_identifier(identifier)
    return nil, nil unless identifier&.include?("@")

    username, domain = identifier.split("@", 2)
    return nil, nil if username.blank? || domain.blank?

    # Username should follow the same requirements as local usernames
    # (at least 3 characters as per Rodauth config)
    return nil, nil if username.length < 3

    [ username, domain ]
  end

  def fetch_oidc_config(domain)
    # Validate domain to prevent SSRF
    unless valid_federated_domain?(domain)
      Rails.logger.error "Invalid domain for OIDC config: #{domain}"
      return nil
    end

    url = "https://#{domain}/.well-known/openid-configuration"

    response = HTTParty.get(url, timeout: 10, headers: {
                              "User-Agent" => "Libreverse/1.0 (Federated Authentication)"
                            })

    if response.success?
      config = JSON.parse(response.body)
      Rails.logger.info "Successfully fetched OIDC config for #{domain}"
      config
    else
      Rails.logger.warn "Failed to fetch OIDC config for #{domain}: HTTP #{response.code}"
      nil
    end
  rescue HTTParty::Error, JSON::ParserError => e
    Rails.logger.error "Error fetching OIDC config for #{domain}: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected error fetching OIDC config for #{domain}: #{e.message}"
    nil
  end

  def register_dynamic_client(registration_endpoint, redirect_uri, oidc_domain:)
    parsed_endpoint = parse_trusted_registration_endpoint(
      registration_endpoint,
      oidc_domain
    )
    unless parsed_endpoint
      Rails.logger.error(
        "Registration endpoint not allowed for #{oidc_domain}: #{registration_endpoint}"
      )
      return { error: "Invalid registration endpoint" }
    end

    client_data = {
      client_name: "Libreverse Instance",
      redirect_uris: [ redirect_uri ],
      scope: "openid profile email",
      grant_types: [ "authorization_code" ],
      response_types: [ "code" ],
      application_type: "web"
    }

    response = HTTParty.post(parsed_endpoint.to_s,
                             body: client_data.to_json,
                             headers: {
                               "Content-Type" => "application/json",
                               "User-Agent" => "Libreverse/1.0 (Federated Authentication)"
                             },
                             timeout: 10)

    if response.success?
      registration_data = JSON.parse(response.body)
      Rails.logger.info "Successfully registered OAuth client"
      registration_data
    else
      Rails.logger.warn "Failed to register OAuth client: HTTP #{response.code}"
      nil
    end
  rescue HTTParty::Error, JSON::ParserError => e
    Rails.logger.error "Error registering OAuth client: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected error registering OAuth client: #{e.message}"
    nil
  end

  def build_federated_username(username, domain)
    # Create a federated username that's unique but readable
    # Format: username@domain but sanitized for local username requirements
    "#{username}@#{domain}"
  end

  def extract_username_from_federated_id(federated_id)
    # Extract just the username part from a federated ID
    return nil unless federated_id&.include?("@")

    federated_id.split("@", 2).first
  end

  private

  def parse_trusted_registration_endpoint(url, oidc_domain)
    return nil unless valid_federated_domain?(oidc_domain)

    parsed = URI.parse(url)
    return nil unless parsed.is_a?(URI::HTTPS)
    return nil if parsed.host.blank?
    return nil if blocked_federated_host?(parsed.host)
    return nil unless registration_host_matches_domain?(parsed.host, oidc_domain)

    parsed
  rescue URI::InvalidURIError
    nil
  end

  def registration_host_matches_domain?(host, oidc_domain)
    host.casecmp?(oidc_domain)
  end

  def valid_federated_domain?(domain)
    return false if domain.blank?
    return false if blocked_federated_host?(domain)

    domain.match?(/\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
  end

  def blocked_federated_host?(host)
    return true if host.blank?

    host.match?(/^(localhost|127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/i) ||
      host.match?(/\A\d{1,3}(?:\.\d{1,3}){3}\z/)
  end
end
