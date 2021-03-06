#!/usr/bin/env ruby
require_relative "../config/environment"

PERIOD_START = ARGV[0].to_s.in_time_zone
PERIOD_END = ARGV[1].to_s.in_time_zone

CSV.open("payments_omein_#{ARGV[0]}_#{ARGV[1]}.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "EMAIL", "RANGO MAXIMO", "RANGO ACTUAL", "RANGO NUEVO", "$ NIVEL 1", "NIVEL 1 IDS", "$ NIVEL 2", "NIVEL 2 IDS", "$ NIVEL 3", "NIVEL 3 IDS", "$ NIVEL 4", "NIVEL 4 IDS", "$ NIVEL 5", "NIVEL 5 IDS", "$ NIVEL 6", "NIVEL 6 IDS", "$ NIVEL 7", "NIVEL 7 IDS", "$ NIVEL 8", "NIVEL 8 IDS", "$ NIVEL 9", "NIVEL 9 IDS", "$ TOTAL" ]
  users = User.joins(:orders).where("orders.created_at >= ? AND orders.created_at < ? AND orders.order_status != ?", PERIOD_START, PERIOD_END, "VALIDATING").order("external_id desc")
    
  users.uniq.each do |user|

    level_1 = 0
    level_2 = 0
    level_3 = 0
    level_4 = 0
    level_5 = 0
    level_6 = 0
    level_7 = 0
    level_8 = 0
    level_9 = 0
    level_1_ids = []
    level_2_ids = []
    level_3_ids = []
    level_4_ids = []
    level_5_ids = []
    level_6_ids = []
    level_7_ids = []
    level_8_ids = []
    level_9_ids = []

    user.payments.where("term_paid = ?", "#{PERIOD_START} - #{PERIOD_END}").each do |payment|
      case payment.payment_type
      when 'OMEIN_LEVEL_1'
        level_1 += payment.amount.round(2) 
        payment.from_users.each do |user|
          level_1_ids << user.external_id
        end
      when 'OMEIN_LEVEL_2'
        level_2 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_2_ids << user.external_id
        end
      when 'OMEIN_LEVEL_3'
        level_3 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_3_ids << user.external_id
        end
      when 'OMEIN_LEVEL_4'
        level_4 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_4_ids << user.external_id
        end
      when 'OMEIN_LEVEL_5'
        level_5 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_5_ids << user.external_id
        end
      when 'OMEIN_LEVEL_6'
        level_6 += payment.amount
        payment.from_users.each do |user|
          level_6_ids << user.external_id
        end
      when 'OMEIN_LEVEL_7'
        level_7 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_7_ids << user.external_id
        end
      when 'OMEIN_LEVEL_8'
        level_8 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_8_ids << user.external_id
        end
      when 'OMEIN_LEVEL_9'
        level_9 += payment.amount.round(2)
        payment.from_users.each do |user|
          level_9_ids << user.external_id
        end
      end

    end

    total = level_1 + level_2 + level_3 + level_4 + level_5 + level_6 + level_7 + level_8 + level_9 
    
    current_summary = user.summaries.where(period_start: PERIOD_START, period_end: PERIOD_END).first
        
    level_1_ids = level_1_ids*"," 
    level_2_ids = level_2_ids*"," 
    level_3_ids = level_3_ids*"," 
    level_4_ids = level_4_ids*"," 
    level_5_ids = level_5_ids*"," 
    level_6_ids = level_6_ids*"," 
    level_7_ids = level_7_ids*"," 
    level_8_ids = level_8_ids*"," 
    level_9_ids = level_9_ids*"," 

    new_rank = current_summary.new_rank ? "*" : ""

    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.email}", "#{user.max_rank}", "#{current_summary.rank}", "#{new_rank}", "#{level_1.round(2)}", "#{level_1_ids}", "#{level_2.round(2)}", "#{level_2_ids}", "#{level_3.round(2)}", "#{level_3_ids}","#{level_4.round(2)}", "#{level_4_ids}", "#{level_5.round(2)}", "#{level_5_ids}", "#{level_6.round(2)}", "#{level_6_ids}", "#{level_7.round(2)}", "#{level_7_ids}", "#{level_8.round(2)}", "#{level_8_ids}", "#{level_9.round(2)}", "#{level_9_ids}", "#{total.round(2)}"]
    csv << user_txt
  end
end

KairosMailer.send(:send_unilevel_commissions_omein, "payments_omein_#{ARGV[0]}_#{ARGV[1]}.csv", "#{PERIOD_START} - #{PERIOD_END}").deliver_now
