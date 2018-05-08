#!/usr/bin/env ruby
require_relative "../config/environment"

not_found = 0
periodo = "CONSUMO ABRIL 2018"

#ID OMEIN,NOMBRES,APELLIDOS,ID PATROCINIO,ID COLOCACION,CONSUMO,ID IUVARE,EMAIL
CSV.foreach(File.path("scripts/final_prana.csv"), { :col_sep => ',' }) do |col|
  omein_id = col[0].to_i
  sponsor_omein_id = col[3].to_i
  placement_omein_id = col[4].to_i
  iuvare_id = col[6].to_s
  email = col[7]
  consumo = col[5]
  user = User.find_by_email(email)
  if user
    if user.external_id != omein_id
      user.external_id = omein_id
      puts "Actualizando usuario #{user.email} de ID #{user.external_id} a ID #{omein_id}"
    end

    if user.placement_external_id != placement_omein_id
      user.placement_external_id = placement_omein_id
      puts "Actualizando usuario #{user.email} de COLOCACION ID #{user.placement_external_id} a COLOCACION ID #{placement_omein_id}"
    end

    if user.sponsor_external_id != sponsor_omein_id
      user.sponsor_external_id = sponsor_omein_id
      puts "Actualizando usuario #{user.email} de PATROCINIO ID #{user.sponsor_external_id} a PATROCINIO ID #{sponsor_omein_id}"
    end

    if user.iuvare_id != iuvare_id
      user.iuvare_id = iuvare_id
      puts "Actualizando usuario #{user.email} de IUVARE ID #{user.iuvare_id} a IUVARE ID #{iuvare_id}"
    end 
  
    if consumo
      order = Order.create!(description: periodo) 
      user.orders << order
      puts "Agregando consumo a usuario #{user.email}"
    end

    user.save!
    
  else
    not_found += 1
    puts "Usuario con ID OMEIN #{omein_id} no encontrado"
  end
end

if not_found != 0
  puts "#{not_found} usuarios no encontrados"
end
