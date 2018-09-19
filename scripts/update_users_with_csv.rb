#!/usr/bin/env ruby
require_relative "../config/environment"

not_found = 0
users_found = []
users_not_found = []

CSV.foreach(File.path("scripts/socios_nuevos_agosto_2018.csv"), { :col_sep => ',' }) do |col|
  omein_id = col[0].to_i
  sponsor_omein_id = col[7].to_i
  placement_omein_id = col[9].to_i
#  iuvare_id = col[6].to_s
  email = col[3]
  phone = col[5]
  phone_alt = col[4]
  created_at = (col[2].to_datetime.end_of_day).in_time_zone("Mexico City").beginning_of_day
#  consumo = col[5]
  user = User.find_by_email(email)
  if user
    if user.external_id != omein_id
      puts "Actualizando usuario #{user.email} de ID #{user.external_id} a ID #{omein_id}"
      user.external_id = omein_id
    end

    if user.placement_external_id != placement_omein_id
      puts "Actualizando usuario #{user.email} de COLOCACION ID #{user.placement_external_id} a COLOCACION ID #{placement_omein_id}"
      user.placement_external_id = placement_omein_id
    end

    if user.sponsor_external_id != sponsor_omein_id
      puts "Actualizando usuario #{user.email} de PATROCINIO ID #{user.sponsor_external_id} a PATROCINIO ID #{sponsor_omein_id}"
      user.sponsor_external_id = sponsor_omein_id
    end

    users_found << user.email
    user.created_at = created_at 

    #if user.iuvare_id != iuvare_id
    #  user.iuvare_id = iuvare_id
    #  puts "Actualizando usuario #{user.email} de IUVARE ID #{user.iuvare_id} a IUVARE ID #{iuvare_id}"
    #end 

    if user.first_name == nil
      names_array = col[1].split(" ")
      case names_array.count
      when 1
        user.first_name = names_array[0]
      when 2
        user.first_name = names_array[0]
        user.last_name = names_array[1]
      when 3
        user.first_name = names_array[0]
        user.last_name = names_array[1] + " " + names_array[2]
      when 4
        user.first_name = names_array[0] + " " + names_array[1] 
        user.last_name = names_array[2] + " " + names_array[3]
      when 5
        user.first_name = names_array[0] + " " + names_array[1] + " " + names_array[2]
        user.last_name = names_array[3] + " " + names_array[4]
      when 6
        user.first_name = names_array[0] + " " + names_array[1] + " " + names_array[2] + " " + names_array[3] 
        user.last_name = names_array[4] + " " + names_array[5]
      end

    end

    user.save!
    
  else
    not_found += 1
    puts "Usuario con ID OMEIN #{omein_id} e email #{email} no encontrado"
    users_not_found << email
    first_name = ""
    last_name = ""

    names_array = col[1].split(" ")
    case names_array.count
    when 1
      first_name = names_array[0]
    when 2
      first_name = names_array[0]
      last_name = names_array[1]
    when 3
      first_name = names_array[0]
      last_name = names_array[1] + " " + names_array[2]
    when 4
      first_name = names_array[0] + " " + names_array[1] 
      last_name = names_array[2] + " " + names_array[3]
    when 5
      first_name = names_array[0] + " " + names_array[1] + " " + names_array[2]
      last_name = names_array[3] + " " + names_array[4]
    when 6
      first_name = names_array[0] + " " + names_array[1] + " " + names_array[2] + " " + names_array[3] 
      last_name = names_array[4] + " " + names_array[5]
    end


    User.create!(first_name: first_name, last_name: last_name, external_id: omein_id, sponsor_external_id: sponsor_omein_id, placement_external_id: placement_omein_id, email: email, phone: phone, phone_alt: phone_alt, created_at: created_at, password: email, password_confirmation: email)
  end
end


users_registered_not_in_list = User.where("email not in (?)", users_found)
puts "#{users_registered_not_in_list.count} usuarios registrados que no están en la lista final"
users_registered_not_in_list.each do |user|
    puts "Usuario con ID OMEIN #{user.external_id} e email #{user.email} no en la lista "
end


if not_found != 0
  puts "#{not_found} usuarios no encontrados"
end
