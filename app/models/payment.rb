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

  def self.omein_add_selling_bonus_20 user, period_start, period_end, from_users, volume_details

    payment_amount = self.get_amount_for_volume_details volume_details, OmeinCompPlan::SELLING_BONUS_20

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_20', amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end

  end

  def self.omein_add_selling_bonus_10 user, period_start, period_end, from_users, volume_details

    payment_amount = self.get_amount_for_volume_details volume_details, OmeinCompPlan::SELLING_BONUS_10

    if payment_amount > 0
      user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_10', amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
    
  end

  def self.omein_add_selling_bonus_4 user, period_start, period_end, from_users, volume_details

    payment_amount = self.get_amount_for_volume_details volume_details, OmeinCompPlan::SELLING_BONUS_4

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: 'OMEIN_SELLING_BONUS_4', amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
    
  end

  def self.omein_add_power_start_25 user, period_start, period_end, from_users, volume_details
    
    payment_amount = self.get_amount_for_volume_details volume_details, OmeinCompPlan::POWER_START_25

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: 'OMEIN_POWER_START_25', amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
    
  end

  def self.omein_add_power_start_15 user, period_start, period_end, from_users, volume_details
    
    payment_amount = self.get_amount_for_volume_details volume_details, OmeinCompPlan::POWER_START_15

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: 'OMEIN_POWER_START_15', amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
    
  end

  def self.prana_add_payment user, period_start, period_end, from_users, level, volume 

    payment_type = "PRANA_LEVEL_#{level}"

    units_ordered = volume/200
    payment_amount = units_ordered*eval("PranaCompPlan::LEVEL_#{level}")

    if payment_amount > 0 
      user.payments << Payment.create!(payment_type: payment_type, amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    else
      return
    end
  end

  def self.omein_add_payment user, period_start, period_end, from_users, level, volume_details

    payment_type = "OMEIN_LEVEL_#{level}"
    payment_amount = self.get_amount_for_volume_details volume_details, eval("OmeinCompPlan::LEVEL_#{level}")

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

    User.update_summaries period_start.beginning_of_month, period_start + 1.month
  end

  def self.get_amount_for_volume_details volume_details, base_percentage

    payment_amount = 0
    volume_details[:items].each do |item|

      item_obj = Item.find(item[:id])

      raise 'Item sin valor comisionable' unless item_obj.commissionable_value 
      payment_amount += base_percentage*item_obj.commissionable_value

    end

    return payment_amount

  end
  
end
