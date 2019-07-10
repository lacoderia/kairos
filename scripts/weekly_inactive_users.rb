#!/usr/bin/env ruby
require_relative "../config/environment"

User.is_active.each do |user|
  last_order = user.orders.order(created_at: :desc).first

  today_one_year_ago = Time.zone.now - 1.year 

  if last_order and last_order.created_at < today_one_year_ago 
    user.update_attribute("active", false)
    puts "inactivando usuario por falta de consumo"
  elsif not last_order and user.created_at < today_one_year_ago 
    user.update_attribute("active", false)
    puts "inactivando usuario porque nunca consumió"
  end
end
