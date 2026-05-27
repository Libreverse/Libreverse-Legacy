require "digest"

class ExperiencesController < ApplicationController
  include EnhancedSpamProtection

  # invisible_captcha is configured in SpamDetection concern
  invisible_captcha only: %i[create update],
                    timestamp_threshold: 3 # Stricter timing for experience submissions

  # CanCanCan authorization
  load_and_authorize_resource except: %i[index display show]

  # Enhanced authentication - require non-guest users for CRUD operations
  before_action :require_authenticated_user, except: %i[index display show]
  before_action :check_enhanced_spam_protection, only: %i[create update]
  before_action :set_experience, only: %i[show edit update destroy display approve]
  before_action :check_ownership, only: %i[edit update destroy]
  before_action :require_admin, only: %i[approve]

  # GET /experiences
  def index
    @experiences = if current_account&.admin?
      Experience.order(created_at: :desc)
    else
      Experience.approved.order(created_at: :desc)
    end

    # Convert to unified experiences for consistent UI
    @experiences = UnifiedExperience.from_search_results(@experiences)
    @experience = Experience.new

    # Generate ETag for conditional requests based on experiences and user role
    # Extract timestamp from loaded collection to avoid additional query
    timestamps = @experiences.map(&:updated_at)
    timestamp = timestamps.any? ? timestamps.max.to_i : 0
    user_role = current_account&.admin? ? "admin" : "user"
    cache_key = "experiences_index/#{user_role}/#{@experiences.size}/#{timestamp}"
    etag = Digest::MD5.hexdigest(cache_key)

    # Handle conditional requests - if content hasn't changed, return 304
    # Skip ETags in development to avoid masking application errors
    return if Rails.env.development?

    # Bail out unless the representation is stale.
    nil unless stale?(etag: etag, public: false)
    # Content has changed or no ETag in request, proceed with rendering
  end

  # GET /experiences/1
  def show
    # If accessed via numeric ID, redirect directly to canonical display path with slug
    return redirect_to display_experience_path(@experience), status: :moved_permanently if params[:id].to_s == @experience.id.to_s && @experience.slug.present?

    redirect_to display_experience_path(@experience)
  end

  # GET /experiences/new
  def new
    @experience = Experience.new
  end

  # POST /experiences
  def create
    @experience = Experience.new(experience_params)
    @experience.account_id = current_account.id if current_account
    @experience.author = current_account.username if current_account
    # User-created experiences are always federated
    @experience.federate = true

    if @experience.save
      redirect_to display_experience_path(@experience), notice: "Experience created successfully."
    else
      @experiences = Experience.all.order(created_at: :desc)
      Rails.logger.warn "EXPERIENCE ERRORS: #{@experience.errors.full_messages.inspect}"
      render :index, status: :unprocessable_entity
    end
  end

  # GET /experiences/1/edit
  def edit
  end

  # PATCH/PUT /experiences/1
  def update
    attrs = experience_params
    attrs[:author] = current_account.username if current_account
    # Ensure user experiences remain federated
    attrs[:federate] = true
    if @experience.update(attrs)
      redirect_to display_experience_path(@experience), notice: "Experience was successfully updated."
    else
      Rails.logger.warn "EXPERIENCE ERRORS: #{@experience.errors.full_messages.inspect}"
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /experiences/1
  def destroy
    @experience.destroy
    redirect_to experiences_path, notice: "Experience was successfully deleted."
  end

  def display
    # Canonicalize: ensure slug in URL for SEO/back-compat
    return redirect_to display_experience_path(@experience), status: :moved_permanently if params[:id].to_s == @experience.id.to_s && @experience.slug.present?

    # Handle local experience
    unless @experience.approved? || current_account&.admin? || @experience.account_id == current_account&.id
      redirect_to experiences_path, alert: "Experience is awaiting approval."
      return
    end
    @experience.reload

    unless @experience.html_file.attached?
      redirect_to experiences_path, alert: "Experience content not found."
      return
    end

    @html_content = @experience.html_file.download.force_encoding("UTF-8")

    # Inject storage access script for secure IndexedDB access
    @html_content = inject_storage_access_client(@html_content)

    # Inject permissions handler script for camera, microphone, sensors, and geolocation
    @html_content = inject_permissions_handler_client(@html_content)

    # Inject keyboard lock handler script for secure keyboard access
    @html_content = inject_keyboard_lock_handler_client(@html_content)

    # Auto-enable P2P for experiences that are not offline-available (multiplayer experiences)
    unless @experience.offline_available
      @is_multiplayer = true
      @session_id = params[:session].presence || "exp_#{@experience.id}_#{SecureRandom.hex(8)}"
      @peer_id = "peer_#{current_account.id}_#{SecureRandom.hex(4)}"

      # Inject WebSocket P2P client library into the experience HTML
      @html_content = inject_websocket_p2p_client(@html_content)
    end

    # Force browsers to treat the data as a download and prevent MIME sniffing
    response.headers["Content-Disposition"] = "inline" # still render in iframe but not downloadable file name
    response.headers["X-Content-Type-Options"] = "nosniff"
  end

  # PATCH /experiences/1/approve
  def approve
    if @experience.update(approved: true)
      redirect_to experiences_path, notice: "Experience approved."
    else
      redirect_to experiences_path, alert: "Unable to approve experience."
    end
  end

  private

  # Require user to be logged in
  def require_authentication
    unless current_account
      flash[:alert] = "You must be logged in to access this page."
      redirect_to "/login"
      return false
    end
    true
  end

  # Check if current user owns the experience
  def check_ownership
    unless @experience.account_id == current_account.id
      flash[:alert] = "You don't have permission to modify this experience."
      redirect_to experiences_path
      return false
    end
    true
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_experience
    identifier = params[:id].to_s
    # Prefer numeric id when the param is strictly digits to preserve old-link semantics
    if identifier.match?(/\A\d+\z/)
      @experience = Experience.find_by(id: identifier)
      return if @experience
    end

    # Otherwise resolve via FriendlyId (slug)
    @experience = Experience.friendly.find(identifier)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Experience not found."
    redirect_to experiences_path
  end

  # Only allow a list of trusted parameters through.
  def experience_params
    # Remove federate from user params - it's now always true for user experiences
    params.require(:experience).permit(:title, :description, :html_file, :offline_available)
  end

  def require_admin
    unless current_account&.admin?
      flash[:alert] = "You must be an admin to perform that action."
      redirect_to experiences_path
      return false
    end
    true
  end

  # Inject WebSocket P2P client library into experience HTML
  def inject_websocket_p2p_client(html_content)
    # Read the P2P client script
    p2p_client_script = File.read(Rails.root.join("app/javascript/libs/websocket_p2p_client.js"))

    # Wrap in script tags
    p2p_script_tag = "<script>#{p2p_client_script}</script>"

    # Inject the script before the closing </head> tag, or before </body> if no </head>
    if html_content.include?("</head>")
      html_content.sub("</head>", "#{p2p_script_tag}\n</head>")
    elsif html_content.include?("</body>")
      html_content.sub("</body>", "#{p2p_script_tag}\n</body>")
    else
      # If no proper HTML structure, append to end
      html_content + p2p_script_tag
    end
  end

  # Inject Storage Access client library into experience HTML
  def inject_storage_access_client(html_content)
    # Read the storage access script
    storage_script = File.read(Rails.root.join("app/javascript/libs/storage_access.js"))

    # Wrap in script tags
    storage_script_tag = "<script>#{storage_script}</script>"

    # Inject the script before the closing </head> tag, or before </body> if no </head>
    if html_content.include?("</head>")
      html_content.sub("</head>", "#{storage_script_tag}\n</head>")
    elsif html_content.include?("</body>")
      html_content.sub("</body>", "#{storage_script_tag}\n</body>")
    else
      # If no proper HTML structure, append to end
      html_content + storage_script_tag
    end
  end

  # Inject Permissions Handler client library into experience HTML
  def inject_permissions_handler_client(html_content)
    # Read the permissions handler script
    permissions_script = File.read(Rails.root.join("app/javascript/libs/permissions_handler.js"))

    # Wrap in script tags
    permissions_script_tag = "<script>#{permissions_script}</script>"

    # Inject the script before the closing </head> tag, or before </body> if no </head>
    if html_content.include?("</head>")
      html_content.sub("</head>", "#{permissions_script_tag}\n</head>")
    elsif html_content.include?("</body>")
      html_content.sub("</body>", "#{permissions_script_tag}\n</body>")
    else
      # If no proper HTML structure, append to end
      html_content + permissions_script_tag
    end
  end

  # Inject Keyboard Lock Handler client library into experience HTML
  def inject_keyboard_lock_handler_client(html_content)
    # Read the keyboard lock handler script
    keyboard_script = File.read(Rails.root.join("app/javascript/libs/keyboard_lock_handler.js"))

    # Wrap in script tags
    keyboard_script_tag = "<script>#{keyboard_script}</script>"

    # Inject the script before the closing </head> tag, or before </body> if no </head>
    if html_content.include?("</head>")
      html_content.sub("</head>", "#{keyboard_script_tag}\n</head>")
    elsif html_content.include?("</body>")
      html_content.sub("</body>", "#{keyboard_script_tag}\n</body>")
    else
      # If no proper HTML structure, append to end
      html_content + keyboard_script_tag
    end
  end
end
