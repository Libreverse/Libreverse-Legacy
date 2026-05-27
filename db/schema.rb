# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_27_220000) do
  create_table "account_active_session_keys", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "session_id", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_use", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id", "session_id"], name: "index_account_active_session_keys_on_account_id_and_session_id", unique: true
    t.index ["session_id"], name: "index_account_active_session_keys_on_session_id", unique: true
  end

  create_table "account_login_change_keys", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
    t.index ["id"], name: "fk_rails_18962144a4"
  end

  create_table "account_password_reset_keys", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", null: false
    t.index ["id"], name: "fk_rails_ccaeb37cea"
  end

  create_table "account_remember_keys", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.index ["id"], name: "fk_rails_9b2f6d8501"
  end

  create_table "account_roles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "role_id"], name: "index_account_roles_on_account_id_and_role_id", unique: true
    t.index ["account_id"], name: "index_account_roles_on_account_id"
    t.index ["role_id"], name: "index_account_roles_on_role_id"
  end

  create_table "account_session_keys", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.index ["id"], name: "fk_rails_86a43d3592"
  end

  create_table "account_verification_keys", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", null: false
    t.datetime "email_last_sent", null: false
    t.index ["id"], name: "fk_rails_2e3b612008"
  end

  create_table "accounts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.string "username", null: false
    t.string "password_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "password_changed_at"
    t.boolean "guest", default: false
    t.boolean "admin", default: false, null: false
    t.string "federated_id"
    t.string "provider"
    t.string "provider_uid"
    t.boolean "system_account", default: false, null: false
    t.index ["admin"], name: "index_accounts_on_admin"
    t.index ["federated_id"], name: "index_accounts_on_federated_id"
    t.index ["guest", "created_at"], name: "index_accounts_on_guest_and_created_at"
    t.index ["provider", "provider_uid"], name: "index_accounts_on_provider_and_provider_uid", unique: true
    t.index ["system_account"], name: "index_accounts_on_system_account"
    t.index ["username"], name: "index_accounts_on_username", unique: true
  end

  create_table "accounts_roles", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "role_id"], name: "index_accounts_roles_on_account_id_and_role_id"
    t.index ["account_id"], name: "index_accounts_roles_on_account_id"
    t.index ["role_id"], name: "index_accounts_roles_on_role_id"
  end

  create_table "action_mailbox_inbound_emails", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_hashcash_stamps", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "version", null: false
    t.integer "bits", null: false
    t.date "date", null: false
    t.string "resource", null: false
    t.string "ext", null: false
    t.string "rand", null: false
    t.string "counter", null: false
    t.string "request_path"
    t.string "ip_address"
    t.json "context"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["counter", "rand", "date", "resource"], name: "index_active_hashcash_stamps_unique", unique: true
    t.index ["ip_address", "created_at"], name: "index_active_hashcash_stamps_on_ip_address_and_created_at"
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_db_files", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ref", null: false
    t.binary "data", size: :long, null: false
    t.datetime "created_at", null: false
    t.index ["ref"], name: "index_active_storage_db_files_on_ref", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits1984_audits", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.bigint "session_id", null: false
    t.bigint "auditor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditor_id"], name: "index_audits1984_audits_on_auditor_id"
    t.index ["session_id"], name: "index_audits1984_audits_on_session_id"
  end

  create_table "blocked_domains", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", null: false
    t.text "reason"
    t.datetime "blocked_at", null: false
    t.string "blocked_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_blocked_domains_on_domain", unique: true
  end

  create_table "blocked_experiences", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "activitypub_uri", null: false
    t.text "reason"
    t.datetime "blocked_at", null: false
    t.string "blocked_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activitypub_uri"], name: "index_blocked_experiences_on_activitypub_uri", unique: true
  end

  create_table "comfy_cms_categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "categorized_type", null: false
    t.index ["site_id", "categorized_type", "label"], name: "index_cms_categories_on_site_id_and_cat_type_and_label", unique: true
  end

  create_table "comfy_cms_categorizations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "categorized_type", null: false
    t.integer "categorized_id", null: false
    t.index ["category_id", "categorized_type", "categorized_id"], name: "index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id", unique: true
  end

  create_table "comfy_cms_files", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", default: "", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["site_id", "position"], name: "index_comfy_cms_files_on_site_id_and_position"
  end

  create_table "comfy_cms_fragments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "record_type"
    t.bigint "record_id"
    t.string "identifier", null: false
    t.string "tag", default: "text", null: false
    t.text "content", size: :medium
    t.boolean "boolean", default: false, null: false
    t.datetime "datetime", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["boolean"], name: "index_comfy_cms_fragments_on_boolean"
    t.index ["datetime"], name: "index_comfy_cms_fragments_on_datetime"
    t.index ["identifier"], name: "index_comfy_cms_fragments_on_identifier"
    t.index ["record_type", "record_id"], name: "index_comfy_cms_fragments_on_record_type_and_record_id"
  end

  create_table "comfy_cms_layouts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "parent_id"
    t.string "app_layout"
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content", size: :medium
    t.text "css", size: :medium
    t.text "js", size: :medium
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["parent_id", "position"], name: "index_comfy_cms_layouts_on_parent_id_and_position"
    t.index ["site_id", "identifier"], name: "index_comfy_cms_layouts_on_site_id_and_identifier", unique: true
  end

  create_table "comfy_cms_pages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "layout_id"
    t.integer "parent_id"
    t.integer "target_page_id"
    t.string "label", null: false
    t.string "slug"
    t.string "full_path", null: false
    t.text "content_cache", size: :medium
    t.integer "position", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["is_published"], name: "index_comfy_cms_pages_on_is_published"
    t.index ["parent_id", "position"], name: "index_comfy_cms_pages_on_parent_id_and_position"
    t.index ["site_id", "full_path"], name: "index_comfy_cms_pages_on_site_id_and_full_path"
  end

  create_table "comfy_cms_revisions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.text "data", size: :medium
    t.datetime "created_at", precision: nil
    t.index ["record_type", "record_id", "created_at"], name: "index_cms_revisions_on_rtype_and_rid_and_created_at"
  end

  create_table "comfy_cms_sites", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "label", null: false
    t.string "identifier", null: false
    t.string "hostname", null: false
    t.string "path"
    t.string "locale", default: "en", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hostname"], name: "index_comfy_cms_sites_on_hostname"
  end

  create_table "comfy_cms_snippets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content", size: :medium
    t.integer "position", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "markdown", default: false
    t.index ["site_id", "identifier"], name: "index_comfy_cms_snippets_on_site_id_and_identifier", unique: true
    t.index ["site_id", "position"], name: "index_comfy_cms_snippets_on_site_id_and_position"
  end

  create_table "comfy_cms_translations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "locale", null: false
    t.integer "page_id", null: false
    t.integer "layout_id"
    t.string "label", null: false
    t.text "content_cache", size: :medium
    t.boolean "is_published", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["is_published"], name: "index_comfy_cms_translations_on_is_published"
    t.index ["locale"], name: "index_comfy_cms_translations_on_locale"
    t.index ["page_id"], name: "index_comfy_cms_translations_on_page_id"
  end

  create_table "comment_likes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id", "account_id"], name: "index_comment_likes_on_comment_id_and_account_id", unique: true
    t.index ["comment_id"], name: "index_comment_likes_on_comment_id"
  end

  create_table "comment_threads", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "commontable_type", null: false
    t.bigint "commontable_id", null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commontable_type", "commontable_id"], name: "idx_comment_threads_poly", unique: true
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "comment_thread_id", null: false
    t.bigint "account_id", null: false
    t.bigint "parent_id"
    t.text "body", null: false
    t.json "mentions_cache", null: false
    t.integer "likes_count", default: 0, null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "moderation_state", default: "pending", null: false
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.json "moderation_flags"
    t.index ["account_id"], name: "index_comments_on_account_id"
    t.index ["comment_thread_id"], name: "index_comments_on_comment_thread_id"
    t.index ["moderation_state"], name: "index_comments_on_moderation_state"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
  end

  create_table "console1984_commands", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "statements"
    t.bigint "sensitive_access_id"
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sensitive_access_id"], name: "index_console1984_commands_on_sensitive_access_id"
    t.index ["session_id", "created_at", "sensitive_access_id"], name: "on_session_and_sensitive_chronologically"
  end

  create_table "console1984_sensitive_accesses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "justification"
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_console1984_sensitive_accesses_on_session_id"
  end

  create_table "console1984_sessions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "reason"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_console1984_sessions_on_created_at"
    t.index ["user_id", "created_at"], name: "index_console1984_sessions_on_user_id_and_created_at"
  end

  create_table "console1984_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_console1984_users_on_username"
  end

  create_table "experience_vectors", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "experience_id", null: false
    t.text "vector_data", null: false
    t.string "vector_hash", null: false
    t.datetime "generated_at", null: false
    t.integer "version", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["experience_id"], name: "index_experience_vectors_on_experience_id", unique: true
    t.index ["generated_at"], name: "index_experience_vectors_on_generated_at"
    t.index ["vector_hash", "experience_id"], name: "index_experience_vectors_on_vector_hash_and_experience_id", unique: true
    t.index ["vector_hash"], name: "index_experience_vectors_on_vector_hash"
  end

  create_table "experiences", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.string "author"
    t.bigint "account_id", null: false
    t.boolean "approved", default: false, null: false
    t.boolean "federate", default: true, null: false
    t.boolean "federated_blocked", default: false, null: false
    t.boolean "offline_available", default: false, null: false
    t.string "source_type", default: "user_created", null: false
    t.bigint "indexed_content_id"
    t.string "metaverse_platform"
    t.text "metaverse_coordinates"
    t.text "metaverse_metadata"
    t.string "slug"
    t.index ["account_id", "created_at"], name: "index_experiences_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_experiences_on_account_id"
    t.index ["approved"], name: "index_experiences_on_approved"
    t.index ["indexed_content_id"], name: "index_experiences_on_indexed_content_id"
    t.index ["metaverse_platform"], name: "index_experiences_on_metaverse_platform"
    t.index ["slug"], name: "index_experiences_on_slug", unique: true
    t.index ["source_type", "metaverse_platform"], name: "index_experiences_on_source_type_and_metaverse_platform"
    t.index ["source_type"], name: "index_experiences_on_source_type"
  end

  create_table "federails_activities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "entity_type", null: false
    t.bigint "entity_id", null: false
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["actor_id"], name: "index_federails_activities_on_actor_id"
    t.index ["entity_type", "entity_id"], name: "index_federails_activities_on_entity"
    t.index ["uuid"], name: "index_federails_activities_on_uuid", unique: true
  end

  create_table "federails_actors", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "federated_url", limit: 500
    t.string "username"
    t.string "server"
    t.string "inbox_url"
    t.string "outbox_url"
    t.string "followers_url"
    t.string "followings_url"
    t.string "profile_url"
    t.integer "entity_id"
    t.string "entity_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.text "public_key"
    t.text "private_key"
    t.json "extensions"
    t.boolean "local", default: false, null: false
    t.string "actor_type"
    t.datetime "tombstoned_at"
    t.index ["entity_type", "entity_id"], name: "index_federails_actors_on_entity", unique: true
    t.index ["federated_url"], name: "index_federails_actors_on_federated_url", unique: true
    t.index ["tombstoned_at"], name: "index_federails_actors_on_tombstoned_at"
    t.index ["uuid"], name: "index_federails_actors_on_uuid", unique: true
  end

  create_table "federails_followings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.bigint "target_actor_id", null: false
    t.integer "status", default: 0, null: false
    t.string "federated_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["actor_id", "target_actor_id"], name: "index_federails_followings_on_actor_id_and_target_actor_id", unique: true
    t.index ["actor_id"], name: "index_federails_followings_on_actor_id"
    t.index ["target_actor_id"], name: "index_federails_followings_on_target_actor_id"
    t.index ["uuid"], name: "index_federails_followings_on_uuid", unique: true
  end

  create_table "federails_moderation_domain_blocks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_federails_moderation_domain_blocks_on_domain", unique: true
  end

  create_table "federails_moderation_reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "federated_url"
    t.bigint "federails_actor_id"
    t.string "object_type"
    t.bigint "object_id"
    t.datetime "resolved_at"
    t.text "content"
    t.text "resolution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["federails_actor_id"], name: "index_federails_moderation_reports_on_federails_actor_id"
    t.index ["object_type", "object_id"], name: "index_federails_moderation_reports_on_object"
  end

  create_table "federated_announcements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "activitypub_uri", null: false
    t.string "title"
    t.string "source_domain", null: false
    t.datetime "announced_at", null: false
    t.string "experience_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activitypub_uri"], name: "index_federated_announcements_on_activitypub_uri", unique: true
    t.index ["announced_at"], name: "index_federated_announcements_on_announced_at"
    t.index ["source_domain"], name: "index_federated_announcements_on_source_domain"
  end

  create_table "friendly_id_slugs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type", "scope"], name: "index_friendly_id_slugs_on_sluggable_type_and_scope"
  end

  create_table "indexed_content_vectors", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "indexed_content_id", null: false
    t.string "vector_hash", null: false
    t.datetime "generated_at", null: false
    t.text "content_hash", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "vector_data"
    t.index ["generated_at"], name: "index_indexed_content_vectors_on_generated_at"
    t.index ["indexed_content_id"], name: "index_indexed_content_vectors_on_indexed_content_id", unique: true
    t.index ["vector_hash", "indexed_content_id"], name: "idx_icv_on_vh_and_icid", unique: true
    t.index ["vector_hash"], name: "index_indexed_content_vectors_on_vector_hash"
  end

  create_table "indexed_contents", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "source_platform", null: false
    t.string "external_id", null: false
    t.string "content_type", null: false
    t.string "title"
    t.text "description"
    t.string "author"
    t.text "metadata", size: :long
    t.text "coordinates"
    t.datetime "last_indexed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_type"], name: "index_indexed_contents_on_content_type"
    t.index ["last_indexed_at"], name: "index_indexed_contents_on_last_indexed_at"
    t.index ["source_platform", "external_id"], name: "index_indexed_contents_on_source_platform_and_external_id", unique: true
    t.index ["source_platform"], name: "index_indexed_contents_on_source_platform"
  end

  create_table "indexing_runs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "indexer_class", null: false
    t.integer "status", default: 0, null: false
    t.text "configuration"
    t.integer "items_processed", default: 0
    t.integer "items_failed", default: 0
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.text "error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["indexer_class"], name: "index_indexing_runs_on_indexer_class"
    t.index ["started_at"], name: "index_indexing_runs_on_started_at"
    t.index ["status"], name: "index_indexing_runs_on_status"
  end

  create_table "instance_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_instance_settings_on_key", unique: true
  end

  create_table "moderation_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "field"
    t.string "model_type"
    t.text "content"
    t.string "reason"
    t.bigint "account_id"
    t.text "violations_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_moderation_logs_on_account_id"
  end

  create_table "oauth_applications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.string "description"
    t.string "homepage_url"
    t.string "redirect_uri", null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.string "registration_access_token"
    t.string "scopes", null: false
    t.datetime "created_at", null: false
    t.string "token_endpoint_auth_method"
    t.string "grant_types"
    t.string "response_types"
    t.string "client_uri"
    t.string "logo_uri"
    t.string "tos_uri"
    t.string "policy_uri"
    t.string "jwks_uri"
    t.string "jwks"
    t.string "contacts"
    t.string "software_id"
    t.string "software_version"
    t.string "sector_identifier_uri"
    t.string "application_type"
    t.string "initiate_login_uri"
    t.string "subject_type"
    t.string "id_token_signed_response_alg"
    t.string "id_token_encrypted_response_alg"
    t.string "id_token_encrypted_response_enc"
    t.string "userinfo_signed_response_alg"
    t.string "userinfo_encrypted_response_alg"
    t.string "userinfo_encrypted_response_enc"
    t.string "request_object_signing_alg"
    t.string "request_object_encryption_alg"
    t.string "request_object_encryption_enc"
    t.string "request_uris"
    t.boolean "require_signed_request_object"
    t.boolean "require_pushed_authorization_requests", default: false, null: false
    t.string "dpop_bound_access_tokens"
    t.string "tls_client_auth_subject_dn"
    t.string "tls_client_auth_san_dns"
    t.string "tls_client_auth_san_uri"
    t.string "tls_client_auth_san_ip"
    t.string "tls_client_auth_san_email"
    t.boolean "tls_client_certificate_bound_access_tokens", default: false
    t.string "post_logout_redirect_uris", null: false
    t.string "frontchannel_logout_uri"
    t.boolean "frontchannel_logout_session_required", default: false
    t.string "backchannel_logout_uri"
    t.boolean "backchannel_logout_session_required", default: false
    t.index ["account_id"], name: "fk_rails_211c1cecac"
    t.index ["client_id"], name: "index_oauth_applications_on_client_id", unique: true
    t.index ["client_secret"], name: "index_oauth_applications_on_client_secret", unique: true
  end

  create_table "oauth_dpop_proofs", primary_key: "jti", id: :string, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "first_use", null: false
  end

  create_table "oauth_grants", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "oauth_application_id"
    t.string "type"
    t.string "code"
    t.string "token"
    t.string "refresh_token"
    t.datetime "expires_in", null: false
    t.string "redirect_uri"
    t.datetime "revoked_at"
    t.string "scopes", null: false
    t.datetime "created_at", null: false
    t.string "access_type", default: "offline", null: false
    t.string "dpop_jwk"
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.string "user_code"
    t.datetime "last_polled_at"
    t.string "certificate_thumbprint"
    t.string "resource"
    t.string "nonce"
    t.string "acr"
    t.string "claims_locales"
    t.string "claims"
    t.string "dpop_jkt"
    t.index ["account_id"], name: "fk_rails_3e095b0b7e"
    t.index ["oauth_application_id", "code"], name: "index_oauth_grants_on_oauth_application_id_and_code", unique: true
    t.index ["refresh_token"], name: "index_oauth_grants_on_refresh_token", unique: true
    t.index ["token"], name: "index_oauth_grants_on_token", unique: true
    t.index ["user_code"], name: "index_oauth_grants_on_user_code", unique: true
  end

  create_table "oauth_pushed_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "oauth_application_id"
    t.string "code", null: false
    t.string "params", null: false
    t.datetime "expires_in", null: false
    t.string "dpop_jkt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_oauth_pushed_requests_on_code", unique: true
    t.index ["oauth_application_id", "code"], name: "index_oauth_pushed_requests_on_oauth_application_id_and_code", unique: true
  end

  create_table "oauth_saml_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "oauth_application_id"
    t.text "idp_cert"
    t.text "idp_cert_fingerprint"
    t.string "idp_cert_fingerprint_algorithm"
    t.boolean "check_idp_cert_expiration"
    t.text "name_identifier_format"
    t.string "audience"
    t.string "issuer", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issuer"], name: "index_oauth_saml_settings_on_issuer", unique: true
    t.index ["oauth_application_id"], name: "fk_rails_73255239bb"
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "solid_cable_messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.binary "payload", size: :long, null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.binary "key", limit: 1024, null: false
    t.binary "value", size: :long, null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.text "error"
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "thredded_categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.string "name", limit: 191, null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "slug", limit: 191, null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci"
  end

  create_table "thredded_messageboard_groups", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "position", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "thredded_user_detail_id", null: false
    t.bigint "thredded_messageboard_id", null: false
    t.datetime "last_seen_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", unique: true
    t.index ["thredded_user_detail_id"], name: "fk_rails_06e42c62f5"
  end

  create_table "thredded_messageboards", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 191, null: false
    t.string "slug", limit: 191
    t.text "description"
    t.integer "topics_count", default: 0
    t.integer "posts_count", default: 0
    t.integer "position", null: false
    t.bigint "last_topic_id"
    t.bigint "messageboard_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "locked", default: false, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug", unique: true
  end

  create_table "thredded_notifications_for_followed_topics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "post_id"
    t.bigint "messageboard_id"
    t.text "post_content"
    t.bigint "post_user_id"
    t.text "post_user_name"
    t.bigint "moderator_id"
    t.integer "moderation_state", null: false
    t.integer "previous_moderation_state", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display"
  end

  create_table "thredded_posts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.text "content"
    t.string "source", limit: 191, default: "web"
    t.bigint "postable_id", null: false
    t.bigint "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["content"], name: "thredded_posts_content_idx", length: 255
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id", "created_at"], name: "index_thredded_posts_on_postable_id_and_created_at"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.text "content"
    t.bigint "postable_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["postable_id", "created_at"], name: "index_thredded_private_posts_on_postable_id_and_created_at"
  end

  create_table "thredded_private_topics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "last_user_id"
    t.string "title", limit: 191, null: false
    t.string "slug", limit: 191, null: false
    t.integer "posts_count", default: 0
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_private_topics_on_last_post_at"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug", unique: true
  end

  create_table "thredded_private_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "private_topic_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "last_user_id"
    t.string "title", limit: 191, null: false
    t.string "slug", limit: 191, null: false
    t.bigint "messageboard_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.boolean "sticky", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.string "hash_id", limit: 20, null: false
    t.integer "moderation_state", null: false
    t.datetime "last_post_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_topics_on_last_post_at"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display"
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true
    t.index ["title"], name: "thredded_topics_title_idx"
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "latest_activity_at", precision: nil
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "last_seen_at", precision: nil
    t.integer "moderation_state", default: 0, null: false
    t.timestamp "moderation_state_changed_at"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations"
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id", unique: true
  end

  create_table "thredded_user_messageboard_preferences", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "messageboard_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "notified_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id", unique: true
  end

  create_table "thredded_user_private_topic_read_states", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.timestamp "read_at", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "reason", limit: 1
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "messageboard_id", null: false
    t.bigint "user_id", null: false
    t.bigint "postable_id", null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.timestamp "read_at", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_id"], name: "index_thredded_user_topic_read_states_on_messageboard_id"
    t.index ["user_id", "messageboard_id"], name: "thredded_user_topic_read_states_user_messageboard"
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
  end

  create_table "user_preferences", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.text "value_ciphertext"
    t.index ["account_id", "key"], name: "index_user_preferences_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_user_preferences_on_account_id"
  end

  add_foreign_key "account_active_session_keys", "accounts"
  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_roles", "accounts"
  add_foreign_key "account_roles", "roles"
  add_foreign_key "account_session_keys", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comment_likes", "comments"
  add_foreign_key "comments", "comment_threads"
  add_foreign_key "experience_vectors", "experiences"
  add_foreign_key "experiences", "accounts"
  add_foreign_key "experiences", "indexed_contents"
  add_foreign_key "federails_activities", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "actor_id"
  add_foreign_key "federails_followings", "federails_actors", column: "target_actor_id"
  add_foreign_key "federails_moderation_reports", "federails_actors"
  add_foreign_key "indexed_content_vectors", "indexed_contents"
  add_foreign_key "moderation_logs", "accounts"
  add_foreign_key "oauth_applications", "accounts"
  add_foreign_key "oauth_grants", "accounts"
  add_foreign_key "oauth_grants", "oauth_applications"
  add_foreign_key "oauth_pushed_requests", "oauth_applications"
  add_foreign_key "oauth_saml_settings", "oauth_applications"
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "accounts", column: "user_id", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "thredded_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "user_preferences", "accounts", on_delete: :cascade
end
