#!/usr/bin/env ruby
require_relative "../config/environment"

PERIOD_START = ARGV[0].to_s.in_time_zone
PERIOD_END = ARGV[1].to_s.in_time_zone

CSV.open("payments_weekly_#{ARGV[0]}_#{ARGV[1]}.csv", "wb") do |csv|
  csv << ["ID OMEIN", "NOMBRE", "APELLIDO", "EMAIL", "$ PRANA QS", "PRANA QS IDS", "$ OMEIN PS 25", "OMEIN PS 25 IDS", "$ PS 15", "PS 15 IDS", "$ COMERC 20", "COMERC 20 IDS", "$ COMERC 10", "COMERC 10 IDS", "$ COMERC 4", "COMERC 4 IDS", "$ TOTAL" ]
  users = User.joins(:orders).where("orders.created_at >= ? AND orders.created_at < ?", PERIOD_START, PERIOD_END).order("external_id desc")
    
  users.uniq.each do |user|

    prana_qs = 0
    ps_25 = 0
    ps_15 = 0
    sb_20 = 0
    sb_10 = 0
    sb_4 = 0
    prana_qs_ids = []
    ps_25_ids = []
    ps_15_ids = []
    sb_20_ids = []
    sb_10_ids = []
    sb_4_ids = []

    user.payments.where("term_paid = ?", "#{PERIOD_START} - #{PERIOD_END}").each do |payment|
      case payment.payment_type
      when 'PRANA_QUICK_START'
        prana_qs += payment.amount.round(2) 
        payment.from_users.each do |user|
          prana_qs_ids << user.external_id
        end
      when 'OMEIN_POWER_START_25'
        ps_25 += payment.amount.round(2) 
        payment.from_users.each do |user|
          ps_25_ids << user.external_id
        end
      when 'OMEIN_POWER_START_15'
        ps_15 += payment.amount.round(2)
        payment.from_users.each do |user|
          ps_15_ids << user.external_id
        end
      when 'OMEIN_SELLING_BONUS_20'
        sb_20 += payment.amount.round(2)
        payment.from_users.each do |user|
          sb_20_ids << user.external_id
        end
      when 'OMEIN_SELLING_BONUS_10'
        sb_10 += payment.amount.round(2)
        payment.from_users.each do |user|
          sb_10_ids << user.external_id
        end
      when 'OMEIN_SELLING_BONUS_4'
        sb_4 += payment.amount.round(2)
        payment.from_users.each do |user|
          sb_4_ids << user.external_id
        end
      end

    end

    total = prana_qs + ps_25 + ps_15 + sb_20 + sb_10 + sb_4 
        
    prana_qs_ids = prana_qs_ids*","
    ps_25_ids = ps_25_ids*"," 
    ps_15_ids = ps_15_ids*"," 
    sb_20_ids = sb_20_ids*"," 
    sb_10_ids = sb_10_ids*"," 
    sb_4_ids = sb_4_ids*","

    user_txt = ["#{user.external_id}", "#{user.first_name}", "#{user.last_name}", "#{user.email}", "#{prana_qs.round(2)}", "#{prana_qs_ids}", "#{ps_25.round(2)}", "#{ps_25_ids}", "#{ps_15.round(2)}", "#{ps_15_ids}", "#{sb_20.round(2)}", "#{sb_20_ids}","#{sb_10.round(2)}", "#{sb_10_ids}", "#{sb_4.round(2)}", "#{sb_4_ids}", "#{total.round(2)}"]
    csv << user_txt
  end
end
