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

ActiveRecord::Schema[8.0].define(version: 2025_02_26_100820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "url", null: false
    t.string "status", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "checked_at"
    t.index "regexp_replace((url)::text, '^https?://(www.)?'::text, ''::text)", name: "index_audits_on_normalized_url"
    t.index ["attempts"], name: "index_audits_on_retryable", where: "(((status)::text = 'failed'::text) AND (attempts > 0))"
    t.index ["site_id"], name: "index_audits_on_site_id"
    t.index ["url"], name: "index_audits_on_url"
  end

  create_table "checks", force: :cascade do |t|
    t.bigint "audit_id", null: false
    t.string "type", null: false
    t.string "status", null: false
    t.datetime "run_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "checked_at"
    t.integer "attempts", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "scheduled", default: false, null: false
    t.index ["attempts"], name: "index_checks_on_retryable", where: "(((status)::text = 'failed'::text) AND (attempts > 0))"
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

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "audits_count", default: 0, null: false
    t.index ["slug"], name: "index_sites_on_slug", unique: true
  end

  add_foreign_key "audits", "sites"
  add_foreign_key "checks", "audits"
end
