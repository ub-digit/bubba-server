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
    next true if value.kind_of?(TrueClass)
    next false if value.kind_of?(FalseClass)
    next 'NULL' if value.nil?
    value = value.strftime("%Y-%m-%d") if value.kind_of?(Date)
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

def create_booking_object(values, type_data)
  db_insert('boknings_objekt', 
    ['obj_id', 'typ', 'lokal_id', 'namn', 'plats', 'ska_kvitteras', 'kommentar', 'aktiv'],
    values
  )
  db_insert('typ_1_grupprum', ['obj_id', 'antal_platser', 'finns_dator', 'finns_tavla'],
    [values[0]] + type_data
  )
end

def create_booking_objects
  create_booking_object([1, 1, 44, 'Grupprum 1', 'Plan 23', true, '', true], [9, true, false])
  create_booking_object([2, 1, 47, 'Grupprum 2', 'Plan 23', true, '', true], [3, true, false])
  create_booking_object([3, 1, 44, 'Grupprum 3', 'Plan 3', true, '', true], [5, false, false])
  create_booking_object([4, 1, 60, 'Grupprum 4', 'Plan 3', true, '', true], [5, true, false])
  create_booking_object([5, 1, 66, 'Grupprum 5', 'Plan 2', true, '', true], [2, false, true])
  create_booking_object([6, 1, 44, 'Grupprum 6', 'Plan 2', true, '', true], [7, true, true])
  create_booking_object([7, 1, 44, 'Grupprum 7', 'Plan 23', true, '', false], [11, true, false])
end

def create_booking(options = {})
  default_options = {
    status: 1,
    type: 1,
    booked: false,
    booked_by: nil,
    display_name: nil
  }
  options = default_options.merge(options)

  options[:pass_day] = Booking.time_to_date(options[:pass_day])
  options[:pass_start] = Booking.time_to_numeric(options[:pass_start])
  options[:pass_stop] = Booking.time_to_numeric(options[:pass_stop])

  db_insert('bokning',
    ['obj_id', 'typ', 'dag', 'start', 'slut', 'bokad', 'bokad_barcode', 'status', 'kommentar'],
    [
     options[:booking_object_id],
     options[:type],
     options[:pass_day],
     options[:pass_start],
     options[:pass_stop],
     options[:booked],
     options[:booked_by],
     options[:status],
     options[:display_name]])
end

def create_bookings(day_offset = nil, location_list = [])
  today = Time.now.to_date.to_time
  today += day_offset.days if day_offset

  location_list.each do |location| 
    BookingObject.where(location_id: location[:id]).each do |obj| 
      pass_start = today + location[:open_time]
      location[:pass_num].times do |i| 
        create_booking(booking_object_id: obj.id, 
          pass_day: today, pass_start: pass_start, pass_stop: pass_start + 2.hours)
        pass_start += 2.hours
      end
    end
  end
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
create_booking_objects
create_bookings(0, [
  {id: 44, pass_num: 5, open_time: 8.hours + 30.minutes},
  {id: 47, pass_num: 4, open_time: 8.hours + 30.minutes},
  {id: 60, pass_num: 7, open_time: 8.hours + 30.minutes},
])
create_bookings(1, [
  {id: 44, pass_num: 5, open_time: 8.hours + 30.minutes},
  {id: 47, pass_num: 4, open_time: 8.hours + 30.minutes},
  {id: 60, pass_num: 7, open_time: 8.hours + 30.minutes},
])
create_bookings(2, [
  {id: 44, pass_num: 5, open_time: 8.hours + 30.minutes},
  {id: 47, pass_num: 4, open_time: 8.hours + 30.minutes},
  {id: 60, pass_num: 7, open_time: 8.hours + 30.minutes},
])
create_bookings(3, [
  {id: 44, pass_num: 5, open_time: 8.hours + 30.minutes},
  {id: 47, pass_num: 4, open_time: 8.hours + 30.minutes},
  {id: 60, pass_num: 7, open_time: 8.hours + 30.minutes},
])
create_bookings(4, [
  {id: 44, pass_num: 5, open_time: 8.hours + 30.minutes},
  {id: 47, pass_num: 4, open_time: 8.hours + 30.minutes},
  {id: 60, pass_num: 7, open_time: 8.hours + 30.minutes},
])
create_bookings(5, [
  {id: 44, pass_num: 3, open_time: 10.hours},
  {id: 60, pass_num: 5, open_time: 9.hours + 30.minutes},
])
create_bookings(6, [
  {id: 60, pass_num: 5, open_time: 9.hours + 30.minutes},
])
