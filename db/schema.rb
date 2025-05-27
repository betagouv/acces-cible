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

ActiveRecord::Schema[8.0].define(version: 2025_05_27_120328) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "url", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "checked_at"
    t.boolean "current", default: false, null: false
    t.boolean "scheduled", default: false
    t.index "regexp_replace((url)::text, '^https?://(www.)?'::text, ''::text)", name: "index_audits_on_normalized_url"
    t.index ["site_id", "current"], name: "index_audits_on_site_id_and_current", unique: true, where: "(current = true)"
    t.index ["site_id"], name: "index_audits_on_site_id"
    t.index ["url"], name: "index_audits_on_url"
  end

  create_table "checks", force: :cascade do |t|
    t.bigint "audit_id", null: false
    t.string "type", null: false
    t.string "status", null: false
    t.datetime "run_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "checked_at"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "scheduled", default: false, null: false
    t.integer "priority", default: 100, null: false
    t.string "error_type"
    t.text "error_message"
    t.string "error_backtrace", default: [], array: true
    t.datetime "retry_at"
    t.integer "retry_count", default: 0, null: false
    t.index ["audit_id"], name: "index_checks_on_audit_id"
    t.index ["status", "run_at"], name: "index_checks_on_status_and_run_at"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "audits_count", default: 0, null: false
    t.bigint "audit_id"
    t.bigint "team_id", null: false
    t.index ["audit_id"], name: "index_sites_on_audit_id"
    t.index ["slug", "team_id"], name: "index_sites_on_slug_and_team_id", unique: true
    t.index ["team_id"], name: "index_sites_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "siret", null: false
    t.string "organizational_unit"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["siret"], name: "index_teams_on_siret", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "email", null: false
    t.string "given_name", null: false
    t.string "usual_name", null: false
    t.string "siret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["siret"], name: "index_users_on_siret"
  end

  add_foreign_key "audits", "sites"
  add_foreign_key "checks", "audits"
  add_foreign_key "sessions", "users"
  add_foreign_key "sites", "audits"
  add_foreign_key "sites", "teams"
  add_foreign_key "users", "teams", column: "siret", primary_key: "siret", name: "fk_users_on_team_siret"
end
