# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bokning", id: false, force: :cascade do |t|
    t.integer "obj_id",                                                            null: false
    t.integer "typ",                                                               null: false
    t.date    "dag"
    t.decimal "start",                     precision: 4, scale: 2,                 null: false
    t.decimal "slut",                      precision: 4, scale: 2,                 null: false
    t.boolean "bokad",                                             default: false
    t.string  "bokad_barcode", limit: 14
    t.integer "status",                                            default: 1
    t.string  "kommentar",     limit: 100
  end

  create_table "bokning_backup", id: false, force: :cascade do |t|
    t.integer "obj_id",                                                            null: false
    t.integer "typ",                                                               null: false
    t.date    "dag"
    t.decimal "start",                     precision: 4, scale: 2,                 null: false
    t.decimal "slut",                      precision: 4, scale: 2,                 null: false
    t.boolean "bokad",                                             default: false
    t.string  "bokad_barcode", limit: 14
    t.integer "status",                                            default: 1
    t.string  "kommentar",     limit: 100
  end

  create_table "boknings_objekt", id: false, force: :cascade do |t|
    t.integer "obj_id",                                    null: false
    t.integer "typ",                                       null: false
    t.integer "lokal_id",                                  null: false
    t.string  "namn",          limit: 100,                 null: false
    t.string  "plats",         limit: 30,                  null: false
    t.boolean "ska_kvitteras"
    t.string  "kommentar",     limit: 200
    t.boolean "aktiv",                     default: true
    t.boolean "intern_bruk",               default: false
  end

  add_index "boknings_objekt", ["obj_id"], name: "boknings_objekt_obj_id_key", unique: true, using: :btree

  create_table "dag_ordning", id: false, force: :cascade do |t|
    t.string  "day",     limit: 10
    t.decimal "ordning",            precision: 1
    t.string  "dag",     limit: 20
  end

  create_table "dagar", id: false, force: :cascade do |t|
    t.string  "dag",     limit: 10
    t.decimal "ordning",            precision: 1
  end

  create_table "gamla_bokningar", id: false, force: :cascade do |t|
    t.integer "obj_id",                                                            null: false
    t.integer "typ",                                                               null: false
    t.date    "dag"
    t.decimal "start",                     precision: 4, scale: 2,                 null: false
    t.decimal "slut",                      precision: 4, scale: 2,                 null: false
    t.boolean "bokad",                                             default: false
    t.string  "bokad_barcode", limit: 14
    t.integer "status",                                            default: 1
    t.string  "kommentar",     limit: 100
  end

  create_table "gamla_openhours", id: false, force: :cascade do |t|
    t.integer "lokal_id",                                                 null: false
    t.string  "day",       limit: 10,                                     null: false
    t.decimal "open",                 precision: 4, scale: 2,             null: false
    t.decimal "close",                precision: 4, scale: 2,             null: false
    t.decimal "prioritet",            precision: 1,           default: 2, null: false
    t.date    "from_dag"
    t.decimal "nummer",               precision: 1
  end

  create_table "lokal", id: false, force: :cascade do |t|
    t.integer "id",               null: false
    t.string  "namn", limit: 100, null: false
    t.text    "name"
  end

  create_table "lokal_sort", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "sort_order"
  end

  create_table "openhours", id: false, force: :cascade do |t|
    t.integer "lokal_id",                                                 null: false
    t.string  "day",       limit: 10,                                     null: false
    t.decimal "open",                 precision: 4, scale: 2,             null: false
    t.decimal "close",                precision: 4, scale: 2,             null: false
    t.decimal "prioritet",            precision: 1,           default: 2, null: false
    t.date    "from_dag"
  end

  create_table "pga_diagrams", primary_key: "diagramname", force: :cascade do |t|
    t.text "diagramtables"
    t.text "diagramlinks"
  end

  create_table "pga_forms", primary_key: "formname", force: :cascade do |t|
    t.text "formsource"
  end

  create_table "pga_graphs", primary_key: "graphname", force: :cascade do |t|
    t.text "graphsource"
    t.text "graphcode"
  end

  create_table "pga_images", primary_key: "imagename", force: :cascade do |t|
    t.text "imagesource"
  end

  create_table "pga_layout", primary_key: "tablename", force: :cascade do |t|
    t.integer "nrcols",   limit: 2
    t.text    "colnames"
    t.text    "colwidth"
  end

  create_table "pga_queries", primary_key: "queryname", force: :cascade do |t|
    t.string "querytype",     limit: 1
    t.text   "querycommand"
    t.text   "querytables"
    t.text   "querylinks"
    t.text   "queryresults"
    t.text   "querycomments"
  end

  create_table "pga_reports", primary_key: "reportname", force: :cascade do |t|
    t.text "reportsource"
    t.text "reportbody"
    t.text "reportprocs"
    t.text "reportoptions"
  end

  create_table "pga_scripts", primary_key: "scriptname", force: :cascade do |t|
    t.text "scriptsource"
  end

  create_table "typ_1_grupprum", id: false, force: :cascade do |t|
    t.integer "obj_id",                                  null: false
    t.decimal "antal_platser",             precision: 3
    t.boolean "finns_dator"
    t.boolean "finns_tavla"
    t.string  "kommentar",     limit: 200
  end

  add_index "typ_1_grupprum", ["obj_id"], name: "typ_1_grupprum_obj_id_key", unique: true, using: :btree

  create_table "typ_2_datorer", id: false, force: :cascade do |t|
    t.integer "obj_id",                                    null: false
    t.boolean "webb"
    t.boolean "ordbehandling"
    t.boolean "skrivare"
    t.string  "kommentar",         limit: 200
    t.integer "extra_tangentbord"
    t.integer "diskettstation",                default: 1
  end

  add_index "typ_2_datorer", ["obj_id"], name: "typ_2_datorer_obj_id_key", unique: true, using: :btree

  create_table "typ_3_lasstudio", id: false, force: :cascade do |t|
    t.integer "obj_id"
    t.boolean "braille"
    t.string  "kommentar", limit: 200
  end

  add_index "typ_3_lasstudio", ["obj_id"], name: "typ_3_lasstudio_obj_id_key", unique: true, using: :btree

  create_table "typ_info", id: false, force: :cascade do |t|
    t.integer "typ"
    t.string  "typ_namn",          limit: 100
    t.integer "timmar_pass"
    t.integer "antal_pass"
    t.integer "dagar_fram"
    t.string  "typ_namn_stor",     limit: 100
    t.date    "from_dag"
    t.text    "type_name"
    t.text    "type_name_heading"
  end

end
