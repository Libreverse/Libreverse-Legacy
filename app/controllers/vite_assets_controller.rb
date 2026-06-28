# frozen_string_literal: true

class ViteAssetsController < ApplicationController
  VITE_PATH_PATTERN = %r{\A[a-zA-Z0-9._/%-]+\z}

  skip_forgery_protection only: :show
  skip_before_action :global_spam_protection_check, only: :show
  skip_before_action :initialize_guest_preferences, only: :show
  skip_before_action :log_request_info, only: :show
  skip_before_action :set_current_ip, only: :show
  skip_before_action :set_locale, only: :show
  skip_after_action :log_response_info, only: :show
  skip_after_action :apply_automatic_caching, only: :show
  skip_after_action :set_compliance_headers, only: :show

  def show
    path = params[:path].to_s
    return head :not_found unless safe_vite_path?(path)

    local_path = Rails.root.join("public/vite", path)
    if local_path.file?
      return send_file(
        local_path,
        disposition: "inline",
        type: Rack::Mime.mime_type(File.extname(path)) || "application/octet-stream"
      )
    end

    return head :not_found unless B2AssetsStorage.enabled?

    redirect_to B2AssetsStorage.public_object_url(path), allow_other_host: true, status: :found
  end

  private

  def safe_vite_path?(path)
    path.present? &&
      !path.include?("..") &&
      !path.start_with?("/") &&
      !path.include?("\0") &&
      path.match?(VITE_PATH_PATTERN) &&
      path.split("/").none? { |segment| segment.in?(%w[. ..]) }
  end
end
