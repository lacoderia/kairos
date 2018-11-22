class Payment < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :from_users, join_table: 'from_users_payments' , association_foreign_key: 'from_user_id', class_name: 'User' 


  PAYMENT_TYPES = [
    'PRANA_QUICK_START',
    'PRANA_LEVEL_1',
    'PRANA_LEVEL_2',
    'PRANA_LEVEL_3',
    'OMEIN_POWER_START_25',
    'OMEIN_POWER_START_15',
    'OMEIN_SELLING_BONUS_20',
    'OMEIN_SELLING_BONUS_10',
    'OMEIN_SELLING_BONUS_4',
    'OMEIN_LEVEL_1',
    'OMEIN_LEVEL_2',
    'OMEIN_LEVEL_3',
    'OMEIN_LEVEL_4',
    'OMEIN_LEVEL_5',
    'OMEIN_LEVEL_6',
    'OMEIN_LEVEL_7',
    'OMEIN_LEVEL_8',
    'OMEIN_LEVEL_9'
  ]
  
  validates :payment_type, inclusion: {in: PAYMENT_TYPES}
  
  def self.prana_add_quick_start user, period_start, period_end, from_users

    if user.quick_start_paid
      raise 'User already has been paid quick start'
    end

    user.payments << Payment.create!(payment_type: 'PRANA_QUICK_START', amount: PranaCompPlan::QUICK_START, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    user.update_attribute(:quick_start_paid, true)
    
  end

  def self.omein_add_selling_bonus_20 user, period_start, period_end, from_users, base_amount

    user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_20', amount: (base_amount*OmeinCompPlan::SELLING_BONUS_20), term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    
  end

  def self.omein_add_selling_bonus_10 user, period_start, period_end, from_users, base_amount

    user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_10', amount: (base_amount*OmeinCompPlan::SELLING_BONUS_10), term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    
  end

  def self.omein_add_selling_bonus_4 user, period_start, period_end, from_users, base_amount

    user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_4', amount: (base_amount*OmeinCompPlan::SELLING_BONUS_4), term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    
  end

  def self.omein_add_power_start_25 user, period_start, period_end, from_users, base_amount

    user.payments << Payment.create!(payment_type: 'OMEIN_POWER_START_25', amount: (base_amount*OmeinCompPlan::POWER_START_25), term_paid: "#{period_start} - #{period_end}", from_users: from_users)

    # TODO: update attribute to mark user's first omein order 
    #user.update_attribute(:quick_start_paid, true)
    
  end

  def self.omein_add_power_start_15 user, period_start, period_end, from_users, base_amount

    user.payments << Payment.create!(payment_type: 'OMEIN_POWER_START_15', amount: (base_amount*OmeinCompPlan::POWER_START_15), term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    
  end

  def self.add_payment user, period_start, period_end, from_users, company, level, volume = 0

    payment_type = "#{company}_LEVEL_#{level}"

    #payment amount
    if company == PranaCompPlan::COMPANY_PRANA
      payment_amount = eval("PranaCompPlan::LEVEL_#{level}")
    elsif company == OmeinCompPlan::COMPANY_OMEIN

      units_ordered = volume/100
      total_comissionable_value = units_ordered*OmeinCompPlan::COMISSIONABLE_VALUE
      payment_amount = eval("OmeinCompPlan::LEVEL_#{level}")*total_comissionable_value
    end

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: payment_type, amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
  end

  def self.calculate_monthly period_start, period_end
    if period_start != (period_end - 1.week)
      raise "Not a valid monthly period"
    end

    OmeinCompPlan.calculate_royalties period_start, period_end
    PranaCompPlan.calculate_royalties period_start, period_end
    
    User.update_summaries period_start, period_end
  end

  def self.calculate_weekly period_start, period_end
    if period_start != (period_end - 1.week)
      raise "Not a valid weekly period"
    end
 
    PranaCompPlan.calculate_quick_starts period_start, period_end
    OmeinCompPlan.calculate_power_starts period_start, period_end
    OmeinCompPlan.calculate_selling_bonus period_start, period_end

    User.update_summaries period_start, period_end
  end
  
end
