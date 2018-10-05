class Summary < ApplicationRecord 
  belongs_to :user

  #user_id, period_start, period_end, current_omein_vg, current_omein_vp, current_prana_vg, current_omein_vp
  #previous_omein_vg, previous_omein_vp, previous_prana_vg, previous_prana_vp, previous_rank

  def self.current_by_user user

    current_period_start = Time.zone.now.beginning_of_month
    current_period_end = Time.zone.now.beginning_of_month + 1.month

    summary = Summary.where("period_start = ? and period_end = ? and user_id = ?", 
      current_period_start, current_period_end, user.id).first
      
    formatted_summary = {current_month: {}, previous_month: {}, ranks: {}}
    I18n.locale = :es

    if summary

      #current month
      current_month = I18n.t Date::MONTHNAMES[summary.period_start.month] 

      formatted_summary[:current_month][:name] = current_month
      formatted_summary[:current_month][:omein_vg] = summary.current_omein_vg 
      formatted_summary[:current_month][:omein_vp] = summary.current_omein_vp
      formatted_summary[:current_month][:prana_vg] = summary.current_prana_vg
      formatted_summary[:current_month][:prana_vp] = summary.current_prana_vp 
      
      #previous month
      previous_month = I18n.t Date::MONTHNAMES[(summary.period_start - 1.month).month]

      formatted_summary[:previous_month][:name] = previous_month
      formatted_summary[:previous_month][:omein_vg] = summary.previous_omein_vg
      formatted_summary[:previous_month][:omein_vp] = summary.previous_omein_vp
      formatted_summary[:previous_month][:prana_vg] = summary.previous_prana_vg
      formatted_summary[:previous_month][:prana_vp] = summary.previous_prana_vp 

      #ranks
      formatted_summary[:ranks][:previous] = summary.previous_rank 
      formatted_summary[:ranks][:max] = user.max_rank

      return formatted_summary

    else

      #current month
      current_month = I18n.t Date::MONTHNAMES[current_period_start.month] 

      formatted_summary[:current_month][:name] = current_month
      formatted_summary[:current_month][:omein_vg] = 0 
      formatted_summary[:current_month][:omein_vp] = 0
      formatted_summary[:current_month][:prana_vg] = 0
      formatted_summary[:current_month][:prana_vp] = 0 
      
      #previous month
      previous_month = I18n.t Date::MONTHNAMES[(current_period_start - 1.month).month]

      formatted_summary[:previous_month][:name] = previous_month
      formatted_summary[:previous_month][:omein_vg] = 0
      formatted_summary[:previous_month][:omein_vp] = 0
      formatted_summary[:previous_month][:prana_vg] = 0
      formatted_summary[:previous_month][:prana_vp] = 0 

      #ranks
      formatted_summary[:ranks][:previous] = "Empresario"
      formatted_summary[:ranks][:max] = "Empresario"

      return formatted_summary

    end
  end
  
end

