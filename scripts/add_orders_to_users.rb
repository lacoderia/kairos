#!/usr/bin/env ruby
require_relative "../config/environment"


puts "REGISTRANDO COMPRAS OMEIN"
compras_omein = 0
CSV.foreach(File.path("scripts/omein_compras_octubre_2018_03.csv"), { :col_sep => ',' }) do |col|

  #["ID", "Nombre", "Orden", "Fecha", "Puntos" ]
  external_id = col[0]
  order_id = col[2]
  created_at = (col[3].to_datetime.end_of_day).in_time_zone("Mexico City").beginning_of_day
  volume = col[4]

  item = Item.find_by(volume: volume, company: "OMEIN")
  unless item
    item = Item.create!(volume: volume, company: "OMEIN")
  end

  user = User.find_by_external_id(external_id)
  if user
    order = Order.find_or_create_by(order_number: order_id)
    order.created_at = created_at
    order.description = "Compra de Omein"
    order.items << item
    order.save!
    user.orders << order
    user.save!
    compras_omein += 1
  end


end
puts "COMPRAS OMEIN REGISTRADAS #{compras_omein}"

puts "REGISTRANDO COMPRAS PRANA"
compras_prana = 0
CSV.foreach(File.path("scripts/prana_compras_octubre_2018_03.csv"), { :col_sep => ',' }) do |col|

  #["Fecha", "ID", "Nombre", "Producto" ]
  created_at = (col[0].to_datetime.end_of_day).in_time_zone("Mexico City").beginning_of_day
  external_id = col[1]
  product_name = col[3]
  
  item = Item.find_by(name: product_name, company: "PRANA")
  
  user = User.find_by_external_id(external_id)
  if user
    order = Order.create!(description: "Compra de Prana")
    order.items << item
    order.created_at = created_at
    order.save!      
    user.orders << order
    user.save!
    compras_prana += 1
  end

end

puts "COMPRAS PRANA REGISTRADAS #{compras_prana}"
