# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181004232355) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "emails", force: :cascade do |t|
    t.bigint "user_id"
    t.string "email_status"
    t.string "email_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_emails_on_user_id"
  end

  create_table "from_users_payments", id: false, force: :cascade do |t|
    t.bigint "from_user_id"
    t.bigint "payment_id"
    t.index ["from_user_id", "payment_id"], name: "index_from_users_payments_on_from_user_id_and_payment_id"
  end

  create_table "invitations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "recipient_name"
    t.string "recipient_email"
    t.string "token"
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "company"
    t.string "name"
    t.string "description"
    t.float "price"
    t.float "commissionable_value"
    t.integer "volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items_orders", id: false, force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "order_id", null: false
    t.index ["item_id", "order_id"], name: "index_items_orders_on_item_id_and_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "order_number"
  end

  create_table "orders_users", id: false, force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.index ["order_id", "user_id"], name: "index_orders_users_on_order_id_and_user_id"
    t.index ["user_id", "order_id"], name: "index_orders_users_on_user_id_and_order_id"
  end

  create_table "payments", force: :cascade do |t|
    t.float "amount"
    t.string "payment_type"
    t.string "term_paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments_users", id: false, force: :cascade do |t|
    t.bigint "payment_id", null: false
    t.bigint "user_id", null: false
    t.index ["payment_id", "user_id"], name: "index_payments_users_on_payment_id_and_user_id"
    t.index ["user_id", "payment_id"], name: "index_payments_users_on_user_id_and_payment_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"
  end

  create_table "shipping_addresses", force: :cascade do |t|
    t.string "address"
    t.string "state"
    t.string "location"
    t.string "zip"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
  end

  create_table "shipping_addresses_users", id: false, force: :cascade do |t|
    t.bigint "shipping_address_id", null: false
    t.bigint "user_id", null: false
    t.index ["shipping_address_id", "user_id"], name: "address_id_user_id"
    t.index ["user_id", "shipping_address_id"], name: "user_id_address_id"
  end

  create_table "summaries", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "period_start"
    t.datetime "period_end"
    t.integer "current_omein_vg"
    t.integer "current_omein_vp"
    t.integer "current_prana_vg"
    t.integer "current_prana_vp"
    t.integer "previous_omein_vg"
    t.integer "previous_omein_vp"
    t.integer "previous_prana_vg"
    t.integer "previous_prana_vp"
    t.string "previous_rank"
    t.index ["user_id"], name: "index_summaries_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.bigint "external_id", null: false
    t.bigint "sponsor_external_id", null: false
    t.bigint "placement_external_id", null: false
    t.string "phone"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.string "transaction_number"
    t.string "iuvare_id"
    t.boolean "quick_start_paid", default: false
    t.string "phone_alt"
    t.string "max_rank", default: "Empresario"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["external_id"], name: "index_users_on_external_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "emails", "users"
  add_foreign_key "invitations", "users"
  add_foreign_key "summaries", "users"
end
