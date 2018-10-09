class Summary < ApplicationRecord 
  belongs_to :user

  validate :one_month_period_only

  def one_month_period_only

    if not period_start == (period_end - 1.month)
      errors.add(:period_start, "no es un periodo válido de un mes")
    end

  end

  #user_id, period_start, period_end, omein_vg, omein_vp, prana_vg, prana_vp, rank
  def self.omein_populate user, period_start, period_end, vp, vg, rank

    current_summary = Summary.find_or_create_by(user: user, period_start: period_start.to_datetime, period_end: period_end.to_datetime)
    current_summary.omein_vp = vp
    current_summary.omein_vg = vg
    current_summary.rank = rank
    current_summary.save!
    
  end

  def self.omein_update user, period_start, period_end, value_hash
    current_summary = Summary.find_or_create_by(user: user, period_start: period_start.to_datetime, period_end: period_end.to_datetime)
    current_summary.update_attributes value_hash
  end

  def self.prana_populate user, period_start, period_end, vp, vg

    current_summary = Summary.find_or_create_by(user: user, period_start: period_start.to_datetime, period_end: period_end.to_datetime)
    current_summary.prana_vp = vp
    current_summary.prana_vg = vg
    current_summary.save!

  end

  def self.populate_all user, previous_rank, period_start, period_end
    
    summary = Summary.new
    summary.user = user

    #period dates
    summary.period_start = period_start
    summary.period_end = period_end

    #omein
    summary.omein_vg = user.omein_get_group_volume period_start, period_end
    summary.omein_vp = user.omein_get_personal_volume period_start, period_end

    #prana
    summary.prana_vg = user.prana_get_group_volume period_start, period_end
    summary.prana_vp = user.prana_get_personal_volume period_start, period_end
    summary.rank = rank

    summary.save!

  end

  def self.by_period_for_user_with_downlines user, period_start, period_end

    downlines = user.placement_downlines
    summary_for_period = Summary.find_or_create_by(user: user, period_start: period_start.to_datetime, period_end: period_end.to_datetime)
    return_data = {user: 
                    {id: user.id, external_id: user.external_id, first_name: user.first_name, last_name: user.last_name}, 
                  summary: 
                    {omein_vp: summary_for_period.omein_vp, omein_vg: summary_for_period.omein_vg, 
                      prana_vp: summary_for_period.prana_vp, prana_vg: summary_for_period.prana_vg, 
                      rank: summary_for_period.rank, period_start: summary_for_period.period_start, 
                      period_end: summary_for_period.period_end}} 

    if downlines.count == 0

      return_data[:downlines] = []
      return return_data

    else

      downlines_with_summary = []

      downlines.each do |downline|
        downlines_with_summary << self.by_period_for_user_with_downlines(downline, period_start, period_end)
      end

      return_data[:downlines] = downlines_with_summary
      return return_data

    end

  end

  def self.current_by_user user

    current_period_start = Time.zone.now.beginning_of_month
    current_period_end = Time.zone.now.beginning_of_month + 1.month

    current_summary = Summary.where("period_start = ? and period_end = ? and user_id = ?", 
      current_period_start, current_period_end, user.id).first

    previous_summary = Summary.where("period_start = ? and period_end = ? and user_id = ?", 
      (current_period_start - 1.month), (current_period_end - 1.month), user.id).first 
      
    formatted_summary = {current_month: {}, previous_month: {}, ranks: {}}
    I18n.locale = :es

    if current_summary

      #current month
      current_month = I18n.t Date::MONTHNAMES[current_summary.period_start.month] 

      formatted_summary[:current_month][:name] = current_month
      formatted_summary[:current_month][:period_start] = current_summary.period_start
      formatted_summary[:current_month][:period_end] = current_summary.period_end
      formatted_summary[:current_month][:omein_vg] = current_summary.omein_vg 
      formatted_summary[:current_month][:omein_vp] = current_summary.omein_vp
      formatted_summary[:current_month][:prana_vg] = current_summary.prana_vg
      formatted_summary[:current_month][:prana_vp] = current_summary.prana_vp 

    else

      #current month
      current_month = I18n.t Date::MONTHNAMES[current_period_start.month] 

      formatted_summary[:current_month][:name] = current_month
      formatted_summary[:current_month][:period_start] = current_period_start
      formatted_summary[:current_month][:period_end] = current_period_end
      formatted_summary[:current_month][:omein_vg] = 0 
      formatted_summary[:current_month][:omein_vp] = 0
      formatted_summary[:current_month][:prana_vg] = 0 
      formatted_summary[:current_month][:prana_vp] = 0 

    end

    if previous_summary
      
      #previous month
      previous_month = I18n.t Date::MONTHNAMES[previous_summary.period_start.month]

      formatted_summary[:previous_month][:name] = previous_month
      formatted_summary[:previous_month][:period_start] = previous_summary.period_start
      formatted_summary[:previous_month][:period_end] = previous_summary.period_end
      formatted_summary[:previous_month][:omein_vg] = previous_summary.omein_vg
      formatted_summary[:previous_month][:omein_vp] = previous_summary.omein_vp
      formatted_summary[:previous_month][:prana_vg] = previous_summary.prana_vg
      formatted_summary[:previous_month][:prana_vp] = previous_summary.prana_vp 

      #ranks
      formatted_summary[:ranks][:previous] = previous_summary.rank 
      formatted_summary[:ranks][:max] = user.max_rank

    else
      
      #previous month
      previous_month = I18n.t Date::MONTHNAMES[(current_period_start - 1.month).month]

      formatted_summary[:previous_month][:name] = previous_month
      formatted_summary[:previous_month][:period_start] = (current_period_start - 1.month)
      formatted_summary[:previous_month][:period_end] = (current_period_end - 1.month)
      formatted_summary[:previous_month][:omein_vg] = 0
      formatted_summary[:previous_month][:omein_vp] = 0
      formatted_summary[:previous_month][:prana_vg] = 0
      formatted_summary[:previous_month][:prana_vp] = 0 

      #ranks
      formatted_summary[:ranks][:previous] = "Inactivo"
      formatted_summary[:ranks][:max] = user.max_rank 

    end
      
    I18n.locale = :en
    return formatted_summary
  end
  
end

