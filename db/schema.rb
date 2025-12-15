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

ActiveRecord::Schema[8.1].define(version: 2025_12_01_152348) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.text "accessibility_page_html"
    t.string "accessibility_page_url"
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.boolean "current", default: false, null: false
    t.text "home_page_html"
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index "regexp_replace((url)::text, '^https?://(www.)?'::text, ''::text)", name: "index_audits_on_normalized_url"
    t.index ["site_id", "current"], name: "index_audits_on_site_id_and_current", unique: true, where: "(current = true)"
    t.index ["site_id"], name: "index_audits_on_site_id"
    t.index ["url"], name: "index_audits_on_url"
  end

  create_table "check_transitions", force: :cascade do |t|
    t.integer "check_id", null: false
    t.datetime "created_at", null: false
    t.json "metadata", default: {}
    t.boolean "most_recent", null: false
    t.integer "sort_key", null: false
    t.string "to_state", null: false
    t.datetime "updated_at", null: false
    t.index ["check_id", "most_recent"], name: "index_check_transitions_parent_most_recent", unique: true, where: "most_recent"
    t.index ["check_id", "sort_key"], name: "index_check_transitions_parent_sort", unique: true
  end

  create_table "checks", force: :cascade do |t|
    t.bigint "audit_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.integer "priority", default: 100, null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["audit_id", "type"], name: "index_checks_on_audit_id_and_type", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "site_tags", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "tag_id", null: false
    t.index ["site_id", "tag_id"], name: "index_site_tags_on_site_id_and_tag_id", unique: true
    t.index ["site_id"], name: "index_site_tags_on_site_id"
    t.index ["tag_id"], name: "index_site_tags_on_tag_id"
  end

  create_table "sites", force: :cascade do |t|
    t.integer "audits_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug", null: false
    t.integer "tags_count", default: 0, null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["slug", "team_id"], name: "index_sites_on_slug_and_team_id", unique: true
    t.index ["team_id"], name: "index_sites_on_team_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "sites_count", default: 0, null: false
    t.string "slug", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "team_id"], name: "index_tags_on_name_and_team_id", unique: true
    t.index ["slug", "team_id"], name: "index_tags_on_slug_and_team_id", unique: true
    t.index ["team_id"], name: "index_tags_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "organizational_unit"
    t.string "siret", null: false
    t.datetime "updated_at", null: false
    t.index ["siret"], name: "index_teams_on_siret", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "provider", null: false
    t.string "siret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["siret"], name: "index_users_on_siret"
  end

  add_foreign_key "audits", "sites"
  add_foreign_key "check_transitions", "checks"
  add_foreign_key "checks", "audits"
  add_foreign_key "sessions", "users"
  add_foreign_key "site_tags", "sites"
  add_foreign_key "site_tags", "tags"
  add_foreign_key "sites", "teams"
  add_foreign_key "tags", "teams"
  add_foreign_key "users", "teams", column: "siret", primary_key: "siret", name: "fk_users_on_team_siret"
end
