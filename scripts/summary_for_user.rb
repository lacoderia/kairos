#!/usr/bin/env ruby
require_relative "../config/environment"

def fetch_summary user, period_start, period_end
  
  result = Summary.by_period_for_user_with_downlines user, period_start, period_end
  usr = result[:user]
  summary = result[:summary]
  downlines = result[:downlines]

  CSV.open("summary_for_user.csv", "wb") do |csv|
    csv << ["NIVEL", "ID", "NOMBRES", "APELLIDOS", "OMEIN VP", "OMEIN VG", "RANGO OMEIN", "RANGO NUEVO", "PRANA VP", "PRANA VG"]

    print_summary csv, usr, summary, downlines, 0

  end

end


def print_summary csv, user, summary, downlines, level
    
  new_rank = summary[:new_rank] ? "*" : ""
  user_txt = ["#{level}", "#{user[:external_id]}", "#{user[:first_name]}", "#{user[:last_name]}", "#{summary[:omein_vp]}", "#{summary[:omein_vg]}", "#{summary[:rank]}", "#{new_rank}", "#{summary[:prana_vp]}", "#{summary[:prana_vg]}"]
  
  csv << user_txt

  if downlines.count == 0
    return
  else
    downlines.each do |downline|
      usr = downline[:user]
      summary = downline[:summary]
      downlines = downline[:downlines]

      print_summary csv, usr, summary, downlines, (level + 1)
    end
  end
end


period_start = Time.zone.now.beginning_of_month - 1.month
period_end = period_start + 1.month
user = User.find_by_external_id(57)

fetch_summary user, period_start, period_end
