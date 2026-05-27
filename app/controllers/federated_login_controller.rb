class FederatedLoginController < ApplicationController
  include FederatedAuthHelper

  def create
    identifier = params[:identifier]&.strip

    if identifier.blank?
      flash[:error] = "Please enter a federated identifier"
      return redirect_to login_path
    end

    username, domain = parse_identifier(identifier)
    unless username && domain
      flash[:error] = "Invalid identifier format. Please use: username@instance.com"
      return redirect_to login_path
    end

    # Fetch OIDC configuration from the domain
    config = fetch_oidc_config(domain)
    unless config
      flash[:error] = "Unable to fetch authentication configuration from #{domain}"
      return redirect_to login_path
    end

    # Check if dynamic client registration is supported
    registration_endpoint = config["registration_endpoint"]
    unless registration_endpoint
      flash[:error] = "The instance #{domain} does not support dynamic client registration"
      return redirect_to login_path
    end

    # Register as an OAuth client
    redirect_uri = "https://#{LibreverseInstance::Application.instance_domain}/auth/federated/callback"
    client_data = register_dynamic_client(
      registration_endpoint,
      redirect_uri,
      oidc_domain: domain,
    )

    unless client_data
      flash[:error] = "Failed to register with #{domain}. Please try again."
      return redirect_to login_path
    end

    # Store client credentials and domain in session for OmniAuth setup
    session[:client_id] = client_data["client_id"]
    session[:client_secret] = client_data["client_secret"]
    session[:oidc_domain] = domain
    session[:federated_username] = username
    session[:federated_identifier] = identifier

    Rails.logger.info "Starting federated authentication for #{identifier}"

    # Redirect to OmniAuth for authentication
    redirect_to "/auth/federated"
  end

  # Handle OmniAuth callback
  def callback
    auth_hash = request.env["omniauth.auth"]

    unless auth_hash
      flash[:error] = "Authentication failed. Please try again."
      return redirect_to login_path
    end

    # Extract user information from the auth hash
    provider_uid = auth_hash["uid"]
    provider = "oidc"
    federated_identifier = session[:federated_identifier]
    federated_username = session[:federated_username]
    oidc_domain = session[:oidc_domain]

    # Clean up session
    session.delete(:client_id)
    session.delete(:client_secret)
    session.delete(:oidc_domain)
    session.delete(:federated_username)
    session.delete(:federated_identifier)

    # Look for existing account with this federated identity
    account = Account.find_by(provider: provider, provider_uid: provider_uid)

    if account
      # Account exists, log them in using Rodauth
      Rails.logger.info "Logging in existing federated user: #{federated_identifier}"

      # Use Rodauth's login functionality
      login_account(account)

      flash[:notice] = "Successfully logged in via federated authentication"
      redirect_to after_login_path
    else
      # Create new account for this federated user
      Rails.logger.info "Creating new federated user: #{federated_identifier}"

      # Create a unique username for the local account
      local_username = build_federated_username(federated_username, oidc_domain || "unknown")

      # Ensure username is unique
      counter = 1
      original_username = local_username
      while Account.exists?(username: local_username)
        local_username = "#{original_username}.#{counter}"
        counter += 1
      end

      # Create the account
      account = Account.new(
        username: local_username,
        federated_id: federated_identifier,
        provider: provider,
        provider_uid: provider_uid,
        status: 2, # verified
        guest: false
      )

      if account.save
        Rails.logger.info "Created new federated account: #{account.id} for #{federated_identifier}"

        # Log them in using Rodauth
        login_account(account)

        flash[:notice] = "Welcome! Your federated account has been created and you are now logged in."
        redirect_to after_login_path
      else
        Rails.logger.error "Failed to create federated account for #{federated_identifier}: #{account.errors.full_messages}"
        flash[:error] = "Failed to create your account. Please try again."
        redirect_to login_path
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error in federated authentication callback: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:error] = "An error occurred during authentication. Please try again."
    redirect_to login_path
  end

  def failure
    error_type = params[:error] || params[:message] || "unknown"
    Rails.logger.warn "Federated authentication failed: #{error_type}"

    # Clean up session
    session.delete(:client_id)
    session.delete(:client_secret)
    session.delete(:oidc_domain)
    session.delete(:federated_username)
    session.delete(:federated_identifier)

    error_message = case error_type
    when "federation_failed"
                      "Federation authentication failed. Please check your identifier and try again."
    when "access_denied"
                      "Access was denied by the authentication provider."
    when "invalid_request"
                      "Invalid authentication request."
    else
                      "Authentication failed. Please try again."
    end

    flash[:error] = error_message
    redirect_to login_path
  end

  def new
    # Show federated login form
    # Pre-fill identifier if coming from a redirect
    @identifier = params[:identifier] || session[:pending_federated_login]
    session.delete(:pending_federated_login) # Clear after use
  end

  private

  def login_path
    # Use Rodauth's login path
    "/login"
  end

  def after_login_path
    # Redirect to dashboard after successful login
    "/dashboard"
  end

  def login_account(account)
    # Set the session to log in the user
    session[:account_id] = account.id
    # This mimics what Rodauth does for login
    session[:authenticated] = true
  end
end
