# frozen_string_literal: true

class DocumentationController < ApplicationController
  # Public documentation (markdown) for the in-app Docsify viewer.
  DOCUMENTATION_ROOT = Rails.root.join("documentation").freeze
  ALLOWED_EXTENSIONS = %w[.md .markdown .html].freeze

  def index
  end

  # Serves markdown (and related) files for Docsify under /docs/content/*
  def content
    relative = sanitize_relative_path(params[:path])
    return head :not_found if relative.blank?

    absolute = DOCUMENTATION_ROOT.join(relative)
    return head :not_found unless absolute.file?
    return head :forbidden unless path_inside_documentation?(absolute)

    ext = absolute.extname.downcase
    return head :not_found unless ALLOWED_EXTENSIONS.include?(ext)

    response.headers["Last-Modified"] = absolute.mtime.httpdate
    content_type = mime_for_extension(ext)

    if request.head?
      response.headers["Content-Type"] = content_type
      head :ok
      return
    end

    send_file absolute,
              type: content_type,
              disposition: "inline",
              filename: absolute.basename.to_s
  end

  private

  def sanitize_relative_path(raw)
    path = raw.to_s
    return nil if path.blank?
    return nil if path.include?("\0")

    cleaned = path.tr("\\", "/").gsub(%r{\A/+}, "")
    return nil if cleaned.blank?
    return nil if cleaned.start_with?("~")
    return nil if cleaned.split("/").any? { |segment| segment.blank? || segment == ".." || segment == "." }

    cleaned
  end

  def path_inside_documentation?(absolute)
    root = DOCUMENTATION_ROOT.expand_path.to_s
    abs = absolute.expand_path.to_s
    abs == root || abs.start_with?(root + File::SEPARATOR)
  end

  def mime_for_extension(ext)
    case ext
    when ".html" then "text/html; charset=utf-8"
    else "text/markdown; charset=utf-8"
    end
  end
end
