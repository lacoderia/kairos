#!/usr/bin/env ruby
require_relative "../config/environment"


CSV.open("users_futura_julio_2018_01.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "FECHA INSCRIPCION", "ID PATROCINIO OMEIN", "ID COLOCACION OMEIN", "EMAIL", "TELEFONO 1", "TELEFONO 2"]
  User.all.order("external_id desc").each do |user|
    address = user.shipping_addresses.first
    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.created_at}", "#{user.sponsor_external_id}", "#{user.placement_external_id}", "#{user.email}", "#{user.phone}", "#{user.phone_alt}"]
    csv << user_txt
  end
end
