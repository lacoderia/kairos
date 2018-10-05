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

    current_summary = Summary.find_or_create_by(user: user, period_start: period_start, period_end: period_end)
    current_summary.omein_vp = vp
    current_summary.omein_vg = vg
    current_summary.save!

    next_summary = Summary.find_or_create_by(user: user, period_start: (period_start + 1.month), period_end: (period_end + 1.month))
    next_summary.omein_vp = vp
    next_summary.omein_vg = vg
    next_summary.rank = rank
    next_summary.save!
    
  end

  def self.prana_populate user, period_start, period_end, vp, vg

    current_summary = Summary.find_or_create_by(user: user, period_start: period_start, period_end: period_end)
    current_summary.prana_vp = vp
    current_summary.prana_vg = vg
    current_summary.save!

    next_summary = Summary.find_or_create_by(user: user, period_start: (period_start + 1.month), period_end: (period_end + 1.month))
    next_summary.prana_vp = vp
    next_summary.prana_vg = vg
    next_summary.save!

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
      formatted_summary[:current_month][:omein_vg] = current_summary.omein_vg 
      formatted_summary[:current_month][:omein_vp] = current_summary.omein_vp
      formatted_summary[:current_month][:prana_vg] = current_summary.prana_vg
      formatted_summary[:current_month][:prana_vp] = current_summary.prana_vp 

    else

      #current month
      current_month = I18n.t Date::MONTHNAMES[current_period_start.month] 

      formatted_summary[:current_month][:name] = current_month
      formatted_summary[:current_month][:omein_vg] = 0 
      formatted_summary[:current_month][:omein_vp] = 0
      formatted_summary[:current_month][:prana_vg] = 0 
      formatted_summary[:current_month][:prana_vp] = 0 

    end

    if previous_summary
      
      #previous month
      previous_month = I18n.t Date::MONTHNAMES[previous_summary.period_start.month]

      formatted_summary[:previous_month][:name] = previous_month
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
      formatted_summary[:previous_month][:omein_vg] = 0
      formatted_summary[:previous_month][:omein_vp] = 0
      formatted_summary[:previous_month][:prana_vg] = 0
      formatted_summary[:previous_month][:prana_vp] = 0 

      #ranks
      formatted_summary[:ranks][:previous] = "Empresario"
      formatted_summary[:ranks][:max] = user.max_rank 

    end
      
    return formatted_summary
  end
  
end

