#!/usr/bin/env ruby
require_relative "../config/environment"


CSV.open("users_prana_4.csv", "wb") do |csv|
  csv << ["ID OMEIN", "ID TRANSACCION", "NOMBRE", "APELLIDO", "ID PATROCINIO OMEIN", "ID COLOCACION OMEIN", "ID IUVARE", "EMAIL", "TELEFONO", "DIRECCION", "ESTADO", "CP", "PAIS"]
  User.all.order("external_id desc").each do |user|
    address = user.shipping_addresses.first
    user_txt = ["#{user.external_id}", "#{user.transaction_number}", "#{user.first_name}", "#{user.last_name}", "#{user.sponsor_external_id}", "#{user.placement_external_id}", "#{user.iuvare_id}", "#{user.email}", "#{user.phone}", "#{address.address}", "#{address.state}", "#{address.zip}", "#{address.country}"]
    csv << user_txt
  end
end
