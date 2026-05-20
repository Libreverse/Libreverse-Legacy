require "chunky_png"
require "base64"

# Thredded configuration

# ==> User Configuration
# The name of the class your app uses for your users.
# Our application uses the `Account` model (ActiveRecord) for authentication (Rodauth + Rolify),
# so point Thredded at that instead of the default `User`.
# Use the ActiveRecord Account model directly so current_account (Rodauth) remains compatible.
# A separate User wrapper exists but is not required; keeping Account avoids extra conversions.
Thredded.user_class = "Account"

# User name column, used in @mention syntax and *must* be unique.
# This is the column used to search for users' names if/when someone is @ mentioned.
Thredded.user_name_column = :username

# User display name method. We already expose `display_username` on `Account`.
Thredded.user_display_name_method = :display_username

# The path (or URL) you will use to link to your users' profiles.
# When linking to a user, Thredded will use this lambda to spit out
# the path or url to your user. This lambda is evaluated in the view context.
# If the lambda returns nil, a span element is returned instead of a link; so
# setting this to always return nil effectively disables all user links.
# Link to a profile path if/when we add one. For now we leverage the existing
# `profile_url` method on Account. If that method returns nil (e.g. guest), Thredded
# will fall back to a span.
Thredded.user_path = lambda { |user|
  user.respond_to?(:profile_url) ? user.profile_url : nil
}

# This method is used by Thredded controllers and views to fetch the currently signed-in user
# Rodauth helper in our app exposes `current_account`.
Thredded.current_user_method = :current_account

Thredded.avatar_url = lambda { |user|
  # Unique cache key for the user (change to taste)
  cache_key = "thredded-avatar-v1-#{user.id}-#{user.updated_at.to_i}"

  Rails.cache.fetch(cache_key, expires_in: 12.hours) do
    require "digest" # Ensure Digest is available

    # Generate MD5 hash of user ID for determinism
    md5_hex = Digest::MD5.hexdigest(user.id.to_s)
    digest = Digest::MD5.digest(user.id.to_s) # Binary for bits

    # Foreground color based on first three bytes of hash
    r = md5_hex[0..1].hex
    g = md5_hex[2..3].hex
    b = md5_hex[4..5].hex
    fg_color = ChunkyPNG::Color.rgb(r, g, b)
    bg_color = ChunkyPNG::Color::WHITE

    # --- Generate PNG ---
    img = ChunkyPNG::Image.new(64, 64, bg_color)

    # Distinct pattern: 5x5 asymmetric grid (no mirroring)
    sprite_size = 5
    pixel_size = 12 # 5 * 12 = 60 pixels, centered in 64x64
    offset = (64 - sprite_size * pixel_size) / 2 # 2

    i = 0 # Bit position counter
    (0...sprite_size).each do |row|
      (0...sprite_size).each do |col|
        # Use bit from hash: 1 if set, for "on" pixel
        byte_idx = i / 8
        bit_pos = 7 - (i % 8)
        if (digest[byte_idx].ord >> bit_pos) & 1 == 1
          # Draw filled rect for this "pixel"
          left = offset + col * pixel_size
          top = offset + row * pixel_size
          right = left + pixel_size - 1
          bottom = top + pixel_size - 1
          img.rect(left, top, right, bottom, fg_color, fg_color)
        end
        i += 1
      end
    end

    # Save PNG to a temp file
    require "tempfile"
    temp_png = Tempfile.new([ "avatar", ".png" ])
    temp_png.binmode
    temp_png.write(img.to_blob)
    temp_png.rewind

    # Process with ImageProcessing to convert to AVIF, falling back to WebP
    require "image_processing"
    format = "avif"
    begin
      processed = ImageProcessing::MiniMagick
                  .source(temp_png.path)
                  .resize_to_limit(64, 64)
                  .convert(format)
                  .call
    rescue StandardError
      format = "webp"
      processed = ImageProcessing::MiniMagick
                  .source(temp_png.path)
                  .resize_to_limit(64, 64)
                  .convert(format)
                  .call
    end

    # Read the processed file
    image_data = File.read(processed.path)

    # Clean up temp files
    temp_png.close
    temp_png.unlink
    processed.close
    processed.unlink

    # Encode to data URL
    require "base64"
    data = Base64.strict_encode64(image_data)
    "data:image/#{format};base64,#{data}"
  end
}

# ==> Permissions Configuration
# By default, thredded uses a simple permission model, where all the users can post to all message boards,
# and admins and moderators are determined by a flag on the users table.

# The name of the moderator flag column on the users table.
Thredded.moderator_column = :admin
# The name of the admin flag column on the users table.
Thredded.admin_column = :admin

# Whether posts and topics pending moderation are visible to regular users.
Thredded.content_visible_while_pending_moderation = false

# This model can be customized further by overriding a handful of methods on the User model.
# For more information, see app/models/thredded/user_extender.rb.

# ==> UI configuration

# How to calculate the position of messageboards in a list:
# :position            (default) set the position manually (new messageboards go to the bottom, by creation timestamp)
# :last_post_at_desc   most recent post first
# :topics_count_desc   most topics first
Thredded.messageboards_order = :position

# Whether admin users see button to delete entire messageboards on the messageboard edit page.
Thredded.show_messageboard_delete_button = true

# Whether MessageboardGroup show page is enabled.
Thredded.show_messageboard_group_page = true

# Whether users that are following a topic are listed on the topic page.
Thredded.show_topic_followers = true

# Whether the list of users who are currently online is displayed.
Thredded.currently_online_enabled = true

# Whether private messaging functionality is enabled.
Thredded.private_messaging_enabled = true

# The number of topics to display per page.
Thredded.topics_per_page = 50

# The number of posts to display per page in a topic.
Thredded.posts_per_page = 25

# Use a custom forum layout that injects the global sidebar & navigation wrappers.
Thredded.layout = "forum"

# We can still override / add view partials under app/views/thredded/**/* when needed.

# ==> Email Configuration
# Email "From:" field will use the following
# (this is also used as the "To" address for both email notifications, as all the recipients are on bcc)
# Thredded.email_from = 'no-reply@example.com'

# Emails going out will prefix the "Subject:" with the following string
# Thredded.email_outgoing_prefix = '[My Forum] '
#
# The parent mailer for all Thredded mailers
# Thredded.parent_mailer = 'ActionMailer::Base'

# ==> Model configuration
# The range of valid messageboard name lengths. Default:
# Thredded.messageboard_name_length_range = (1..60)
#
# The range of valid topic title lengths. Default:
# Thredded.topic_title_length_range = (1..200)

# ==> Routes and URLs
# How Thredded generates URL slugs from text:

# Default:
Thredded.slugifier = ->(input) { input.parameterize }

# If your forum is in a language other than English, you might want to use the babosa gem instead
# Thredded.slugifier = ->(input) { Babosa::Identifier.new(input).normalize.transliterate(:russian).to_s }

# By default, thredded uses integers for record ID route constraints.
# For integer based IDs (default):
# Thredded.routes_id_constraint = /[1-9]\d*/
#
# For UUID based IDs (example):
# Thredded.routes_id_constraint = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

# ==> Post Content Formatting
# Customize the way Thredded handles post formatting.

# ===> Emoji using the 'gemoji' gem
# 1. Install `gemoji` following instruction at https://github.com/github/gemoji.
# 2. Uncomment the following line:
Thredded::ContentFormatter.after_markup_filters.insert(1, HTML::Pipeline::EmojiFilter)

# Change the HTML sanitization settings used by Thredded.
# See the Sanitize docs for more information on the underlying library: https://github.com/rgrove/sanitize/#readme
# E.g. to allow a custom element <custom-element>:
# Thredded::ContentFormatter.allowlist[:elements] += %w(custom-element)

# ==> User autocompletion (Private messages and @-mentions)
Thredded.autocomplete_min_length = 1

# ==> Error Handling
# By default Thredded just renders a flash alert on errors such as Topic not found, or Login required.
# Below is an example of overriding the default behavior on LoginRequired:
#
# Rails.application.config.to_prepare do
#   Thredded::ApplicationController.module_eval do
#     # Render sign in page:
#     rescue_from Thredded::Errors::LoginRequired do |exception|
#       flash.now[:notice] = exception.message
#       controller = Users::SessionsController.new
#       controller.request = request
#       controller.request.env['devise.mapping'] = Devise.mappings[:user]
#       controller.response = response
#       controller.response_options = { status: :forbidden }
#       controller.process(:new)
#     end
#   end
# end

# ==> View hooks
#
# Customize the UI before/after/replacing individual components.
# See the full list of view hooks and their arguments by running:
#
#     $ grep view_hooks -R --include '*.html.erb' "$(bundle show thredded)"
#
# Rails.application.config.to_prepare do
#   Thredded.view_hooks.post_form.content_text_area.config.before do |form:, **args|
#     # This is called in the Thredded view context, so all Thredded helpers and URLs are accessible here directly.
#     'hi'
#   end
# end

# ==> Topic following
#
# By default, a user will be subscribed to a topic they've created. Uncomment this to not subscribe them:
#
# Thredded.auto_follow_when_creating_topic = false
#
# By default, a user will be subscribed to (follow) a topic they post in. Uncomment this to not subscribe them:
#
# Thredded.auto_follow_when_posting_in_topic = false
#
# By default, a user will be subscribed to the topic they get @-mentioned in.
# Individual users can disable this in the Notification Settings.
# To change the default for all users, simply change the default value of the `follow_topics_on_mention` column
# of the `thredded_user_preferences` and `thredded_user_messageboard_preferences` tables.

# ==> Notifiers
# Our instance does not (yet) send forum emails. Disable for now to avoid queued mail.
Thredded.notifiers = []

# When enabling, re-add: `Thredded.notifiers = [Thredded::EmailNotifier.new]` and configure sender.

# --- Additional Libreverse Integration -------------------------------------------------------
# Ensure permissions align with our admin flag. Thredded inspects `admin?` / `moderator?`.
# We already mapped both moderator/admin columns to :admin, so no extra override required.

# If we later need per‑messageboard granular permissions, we can implement a custom
# permissions class and assign via: `Thredded.user_permissions_class = 'ForumUserPermissions'`.

# Content formatting: allow basic markdown (default pipeline already includes Kramdown).
# Optionally we could add emoji filter once the gemoji assets are integrated.
# Example (left commented until assets in place):
# Thredded::ContentFormatter.after_markup_filters.insert(1, HTML::Pipeline::EmojiFilter)

# Performance: current DB (TiDB via Trilogy) doesn't support MySQL FULLTEXT indexes identically.
# The migration already fell back to regular indexes; search will be substring based.

# Monkey patch to fix compatibility issue with Rails 8 and Ruby 3.4
# The deprecated whitelist method tries to call ActiveSupport::Deprecation.warn
# which is now private. Override it to avoid the error.
module Thredded
  class ContentFormatter
    class << self
      def whitelist
        allowlist
      end
    end
  end
end
