#!/usr/bin/env ruby
require_relative "../config/environment"


CSV.open("payments_prana.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "EMAIL", "$ BONO RAPIDO", "IDS BONO RAPIDO", "$ NIVEL 1", "NIVEL 1 IDS", "$ NIVEL 2", "NIVEL 2 IDS", "$ NIVEL 3", "NIVEL 3 IDS", "$ TOTAL", "$ MAXIMO" ]
  users = User.joins(:orders).where("orders.created_at between ? AND ?", "2018-05-01", "2018,06-01").order("external_id desc")
    
  users.uniq.each do |user|

    quick_start = 0
    level_1 = 0
    level_2 = 0
    level_3 = 0
    quick_start_ids = []
    level_1_ids = []
    level_2_ids = []
    level_3_ids = []

    user.payments.each do |payment|
      case payment.payment_type
      when 'QUICK_START'
        quick_start += Payment::QUICK_START
        payment.from_users.each do |user|
          quick_start_ids << user.external_id 
        end
      when 'LEVEL_1'
        level_1 += Payment::LEVEL_1
        payment.from_users.each do |user|
          level_1_ids << user.external_id
        end
      when 'LEVEL_2'
        level_2 += Payment::LEVEL_2
        payment.from_users.each do |user|
          level_2_ids << user.external_id
        end
      when 'LEVEL_3'
        level_3 += Payment::LEVEL_3
        payment.from_users.each do |user|
          level_3_ids << user.external_id
        end
      end
    end

    total = level_1 + level_2 + level_3 + quick_start
    total_maximo = total
    if (level_1 + level_2 + level_3) >= 11400
      total_maximo = 11400 + quick_start
    end
        
    quick_start_ids = quick_start_ids*"," 
    level_1_ids = level_1_ids*"," 
    level_2_ids = level_2_ids*"," 
    level_3_ids = level_3_ids*"," 

    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.email}", "#{quick_start}", "#{quick_start_ids}", "#{level_1}", "#{level_1_ids}", "#{level_2}", "#{level_2_ids}", "#{level_3}", "#{level_3_ids}", "#{total}", "#{total_maximo}"]
    csv << user_txt
  end
end
