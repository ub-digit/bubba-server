# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

def execute(query)
  ActiveRecord::Base.connection.execute(query)
end

def db_insert(table, fields, values)
  field_list = fields.join(", ")
  values = values.map do |value| 
    next value if value.kind_of?(Numeric)
    quoted_value = value.gsub(/\'/, "''")
    "'#{quoted_value}'"
  end.join(", ")
  execute("INSERT INTO #{table} (#{field_list}) VALUES(#{values})")
end

def create_view(name, query)
  execute("CREATE VIEW #{name} AS #{query};")
end

def create_locations
  db_insert('lokal', ['id', 'name', 'namn'], [44, 'Test Library 1', 'Testbibliotek 1'])
  db_insert('lokal', ['id', 'name', 'namn'], [60, 'Test Center 2', 'Testtorg 2'])
  db_insert('lokal', ['id', 'name', 'namn'], [47, 'Test Library 3', 'Testbibliotek 3'])
  db_insert('lokal', ['id', 'name', 'namn'], [66, 'Test Center 4', 'Testtorg 4'])
  db_insert('lokal_sort', ['id', 'sort_order'], [44, 0])
  db_insert('lokal_sort', ['id', 'sort_order'], [47, 0])
  db_insert('lokal_sort', ['id', 'sort_order'], [60, 1])
  db_insert('lokal_sort', ['id'], [66])
end

create_view("booking_objects", 
  "SELECT bo.obj_id AS id,
    bo.typ AS object_type,
    bo.lokal_id AS location_id,
    bo.namn AS name,
    bo.plats AS place,
    bo.ska_kvitteras AS require_confirmation,
    bo.kommentar AS comment,
    bo.aktiv AS active,
    bo.intern_bruk AS internal,
    t.antal_platser AS seats,
    t.finns_dator AS has_computer,
    t.finns_tavla AS has_whiteboard
   FROM (boknings_objekt bo
     JOIN typ_1_grupprum t ON ((t.obj_id = bo.obj_id)))")

create_view("bookings",
  "SELECT bokning.oid AS id,
    bokning.obj_id AS booking_object_id,
    bokning.dag AS pass_day,
    bokning.start AS pass_start,
    bokning.slut AS pass_stop,
    bokning.bokad AS booked,
    bokning.bokad_barcode AS booked_by,
    bokning.status,
    bokning.kommentar AS display_name
   FROM bokning")

create_view("locations",
  "SELECT l.id,
    l.name AS english_name,
    l.namn AS swedish_name,
    ls.sort_order
   FROM (lokal l
     JOIN lokal_sort ls ON ((l.id = ls.id)))")

create_locations
