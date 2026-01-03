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

ActiveRecord::Schema[8.1].define(version: 2026_01_04_101500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "campfire_messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "campfire_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["campfire_room_id"], name: "index_campfire_messages_on_campfire_room_id"
    t.index ["created_at"], name: "index_campfire_messages_on_created_at"
    t.index ["user_id"], name: "index_campfire_messages_on_user_id"
  end

  create_table "campfire_participants", force: :cascade do |t|
    t.bigint "campfire_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.string "peer_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["campfire_room_id", "peer_id"], name: "index_campfire_participants_on_campfire_room_id_and_peer_id", unique: true
    t.index ["campfire_room_id"], name: "index_campfire_participants_on_campfire_room_id"
    t.index ["user_id"], name: "index_campfire_participants_on_user_id"
  end

  create_table "campfire_rooms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "ended_at"
    t.datetime "last_empty_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_campfire_rooms_on_active"
    t.index ["created_by_id"], name: "index_campfire_rooms_on_created_by_id"
    t.index ["name"], name: "index_campfire_rooms_on_name", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "message_type", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
    t.index ["message_type"], name: "index_chat_messages_on_message_type"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "chat_reactions", force: :cascade do |t|
    t.bigint "chat_message_id", null: false
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_message_id", "user_id", "emoji"], name: "index_chat_reactions_on_chat_message_id_and_user_id_and_emoji", unique: true
    t.index ["chat_message_id"], name: "index_chat_reactions_on_chat_message_id"
    t.index ["user_id"], name: "index_chat_reactions_on_user_id"
  end

  create_table "file_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "folder_id"
    t.string "quarantine_reason"
    t.datetime "scanned_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.index ["folder_id"], name: "index_file_entries_on_folder_id"
    t.index ["status"], name: "index_file_entries_on_status"
    t.index ["uploaded_by_id"], name: "index_file_entries_on_uploaded_by_id"
  end

  create_table "file_folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["parent_id", "name"], name: "index_file_folders_on_parent_id_and_name", unique: true
    t.index ["parent_id"], name: "index_file_folders_on_parent_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.integer "role", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["invited_by_id"], name: "index_invites_on_invited_by_id"
    t.index ["token"], name: "index_invites_on_token", unique: true
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "chat_message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_message_id", "user_id"], name: "index_mentions_on_chat_message_id_and_user_id", unique: true
    t.index ["chat_message_id"], name: "index_mentions_on_chat_message_id"
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "post_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body_markdown", null: false
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["status"], name: "index_posts_on_status"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "chat_color", default: "phosphor_green", null: false
    t.string "chat_sound", default: "beep", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "files_read", default: true, null: false
    t.boolean "files_upload", default: false, null: false
    t.string "handle", null: false
    t.datetime "last_signed_in_at"
    t.datetime "magic_link_expires_at"
    t.datetime "magic_link_sent_at"
    t.string "magic_link_token"
    t.integer "mic_mode", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.datetime "status_expires_at"
    t.string "status_message"
    t.datetime "updated_at", null: false
    t.index ["chat_color"], name: "index_users_on_chat_color"
    t.index ["chat_sound"], name: "index_users_on_chat_sound"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["handle"], name: "index_users_on_handle", unique: true
    t.index ["magic_link_token"], name: "index_users_on_magic_link_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "campfire_messages", "campfire_rooms"
  add_foreign_key "campfire_messages", "users"
  add_foreign_key "campfire_participants", "campfire_rooms"
  add_foreign_key "campfire_participants", "users"
  add_foreign_key "campfire_rooms", "users", column: "created_by_id"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "chat_reactions", "chat_messages"
  add_foreign_key "chat_reactions", "users"
  add_foreign_key "file_entries", "file_folders", column: "folder_id"
  add_foreign_key "file_entries", "users", column: "uploaded_by_id"
  add_foreign_key "file_folders", "file_folders", column: "parent_id"
  add_foreign_key "invites", "users", column: "invited_by_id"
  add_foreign_key "mentions", "chat_messages"
  add_foreign_key "mentions", "users"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
end
