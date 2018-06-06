#!/usr/bin/env ruby
require_relative "../config/environment"


CSV.open("users_prana_6.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "ID PATROCINIO OMEIN", "ID COLOCACION OMEIN", "ID IUVARE", "EMAIL", "BONO PRANA COBRADO?", "TELEFONO", "DIRECCION", "ESTADO", "CP", "PAIS"]
  User.all.order("external_id desc").each do |user|
    address = user.shipping_addresses.first
    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.sponsor_external_id}", "#{user.placement_external_id}", "#{user.iuvare_id}", "#{user.email}", "#{user.quick_start_paid}", "#{user.phone}", "#{address.address}", "#{address.state}", "#{address.zip}", "#{address.country}"]
    csv << user_txt
  end
end
