#!/usr/bin/env ruby
require_relative "../config/environment"

PERIOD_START = ARGV[0].to_s.in_time_zone
PERIOD_END = ARGV[1].to_s.in_time_zone

CSV.open("payments_prana_#{ARGV[0]}_#{ARGV[1]}.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "EMAIL", "$ BONO RAPIDO", "IDS BONO RAPIDO", "$ BONO DIFERIDO", "IDS BONO DIFERIDO", "$ NIVEL 1", "NIVEL 1 IDS", "$ NIVEL 2", "NIVEL 2 IDS", "$ NIVEL 3", "NIVEL 3 IDS", "$ TOTAL", "$ MAXIMO" ]
  users = User.joins(:orders).where("orders.created_at >= ? AND orders.created_at < ?", PERIOD_START, PERIOD_END).order("external_id desc")
    
  users.uniq.each do |user|

    quick_start = 0
    deferred_quick_start = 0
    level_1 = 0
    level_2 = 0
    level_3 = 0
    quick_start_ids = []
    deferred_quick_start_ids = []
    level_1_ids = []
    level_2_ids = []
    level_3_ids = []

    user.payments.where("term_paid = ?", "#{PERIOD_START} - #{PERIOD_END}").each do |payment|
      case payment.payment_type
      when 'PRANA_QUICK_START'
        quick_start += payment.amount 
        payment.from_users.each do |user|
          quick_start_ids << user.external_id 
        end
      when 'PRANA_DEFERRED_QUICK_START'
        dferred_quick_start += payment.amount
        payment.from_users.each do |user|
          deferred_quick_start_ids << user.external_id 
        end
      when 'PRANA_LEVEL_1'
        level_1 += payment.amount
        payment.from_users.each do |user|
          level_1_ids << user.external_id
        end
      when 'PRANA_LEVEL_2'
        level_2 += payment.amount
        payment.from_users.each do |user|
          level_2_ids << user.external_id
        end
      when 'PRANA_LEVEL_3'
        level_3 += payment.amount
        payment.from_users.each do |user|
          level_3_ids << user.external_id
        end
      end
    end

    total = level_1 + level_2 + level_3 + quick_start + deferred_quick_start
    total_maximo = total
    if (level_1 + level_2 + level_3) >= 11400
      total_maximo = 11400 + quick_start + deferred_quick_start
    end
        
    quick_start_ids = quick_start_ids*"," 
    deferred_quick_start_ids = deferred_quick_start_ids*"," 
    level_1_ids = level_1_ids*"," 
    level_2_ids = level_2_ids*"," 
    level_3_ids = level_3_ids*"," 

    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.email}", "#{quick_start.round(2)}", "#{quick_start_ids}", "#{deferred_quick_start.round(2)}", "#{deferred_quick_start_ids}", "#{level_1.round(2)}", "#{level_1_ids}", "#{level_2.round(2)}", "#{level_2_ids}", "#{level_3.round(2)}", "#{level_3_ids}", "#{total.round(2)}", "#{total_maximo.round(2)}"]
    csv << user_txt
  end
end

KairosMailer.send(:send_unilevel_commissions_prana, "payments_prana_#{ARGV[0]}_#{ARGV[1]}.csv", "#{PERIOD_START} - #{PERIOD_END}").deliver_now
