class Payment < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :from_users, join_table: 'from_users_payments' , association_foreign_key: 'from_user_id', class_name: 'User' 

  PRANA_QUICK_START = 4000.00
  PRANA_LEVEL_1 = 200.00
  PRANA_LEVEL_2 = 600.00
  PRANA_LEVEL_3 = 200.00
  ACTIVE_DOWNLINES_FOR_QUICK_START = 3
  ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE = 3
  MAX_VOLUME_IN_OMEIN = 200
  MIN_VOLUME_IN_OMEIN = 100

  PAYMENT_TYPES = [
    'PRANA_QUICK_START',
    'PRANA_LEVEL_1',
    'PRANA_LEVEL_2',
    'PRANA_LEVEL_3',
  ]

  COMPANY_PRANA = "PRANA"
  COMPANY_OMEIN = "OMEIN"
  
  validates :payment_type, inclusion: {in: PAYMENT_TYPES}

  def self.add_payment user, period_start, period_end, from_users, company, level

    payment_type = "#{company}_LEVEL_#{level}"
    payment_amount = eval(payment_type)

    user.payments << Payment.create!(payment_type: payment_type, amount: payment_amount, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
  end

  # PRANA

  def self.prana_add_quick_start user, period_start, period_end, from_users
    user.payments << Payment.create!(payment_type: 'PRANA_QUICK_START', amount: PRANA_QUICK_START, term_paid: "#{period_start} - #{period_end}", from_users: from_users)
    user.update_attribute(:quick_start_paid, true)
  end

  #period_start ~ '2018-04-01'
  #period_end ~ '2018-05-01'
  def self.prana_calculate_quick_starts period_start, period_end, launch_event

    users = User.joins(:orders).where("users.quick_start_paid = ? AND orders.created_at between ? AND ?", false, period_start, period_end).order("external_id desc").uniq

    puts "#{users.count} usuarios con consumo en el periodo #{period_start} - #{period_end}"
    
    quick_start_payments = 0

    users.each do |user|

      unless user.prana_active_for_period period_start, period_end, true
        next
      end

      downlines = user.placement_downlines 

      if downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
        active_downlines = []
        inactive_downlines = []
        
        downlines.each do |downline|
          if launch_event
            prana_orders_in_period = downline.orders.joins(:items).where("items.company = ? AND orders.created_at between ? and ?", 
                                                                         COMPANY_PRANA, period_start, period_end).count
          else
            sign_up_in_prana = user.created_at.beginning_of_day 
            deadline = sign_up_in_prana + 1.month + 1.day
            prana_orders_in_period = downline.orders.joins(:items).where("items.company = ? AND orders.created_at between ? and ?",
                                                                         COMPANY_PRANA, sign_up_in_prana, deadline).count
          end

          if prana_orders_in_period > 0
            active_downlines << downline
          else
            inactive_downlines << downline
          end
        end

        if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
          Payment.prana_add_quick_start user, period_start, period_end, active_downlines
          puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period_start} - #{period_end}"
          quick_start_payments += 1
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, COMPANY_PRANA
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
              Payment.prana_add_quick_start user, period_start, period_end, active_downlines
              puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period_start} - #{period_end}"
              quick_start_payments += 1
              break          
            end
          end
        end
      end
    end

    puts "#{quick_start_payments} pagos de power start en el periodo #{period_start} - #{period_end}"

  end

  def self.prana_calculate_royalties period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at between ? AND ?", COMPANY_PRANA, period_start, period_end).order("external_id desc").uniq

    puts "#{users.count} usuarios con consumo en el periodo #{period_start} - #{period_end}"

    level_1_payments = 0
    level_2_payments = 0
    level_3_payments = 0

    users.each do |user|

      if user.placement_upline
        uplines = User.prana_check_activity_recursive_upline_3_levels_no_compression(user.placement_upline, [],
                                                                                            period_start, period_end)

        puts "pagos del usuario #{user.email}"

        if uplines[0] and uplines[0][:eligible]
          Payment.add_payment uplines[0][:upline], period_start, period_end, [user], COMPANY_PRANA, 1
          level_1_payments += 1
          puts "pago de nivel 1 al usuario #{uplines[0][:upline].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[1] and uplines[1][:eligible]
          Payment.add_payment uplines[1][:upline], period_start, period_end, [user], COMPANY_PRANA, 2
          level_2_payments += 1 
          puts "pago de nivel 2 al usuario #{uplines[1][:upline].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[2] and uplines[2][:eligible]
          Payment.add_payment uplines[2][:upline], period_start, period_end, [user], COMPANY_PRANA, 3
          level_3_payments += 1 
          puts "pago de nivel 3 al usuario #{uplines[2][:upline].email} en el periodo #{period_start} - #{period_end}"
        end
      
      end

    end
    
    puts "#{level_1_payments} pagos de nivel 1 start en el periodo #{period_start} - #{period_end}"
    puts "#{level_2_payments} pagos de nivel 2 start en el periodo #{period_start} - #{period_end}"
    puts "#{level_3_payments} pagos de nivel 3 start en el periodo #{period_start} - #{period_end}"
    puts "TOTAL: #{level_1_payments*PRANA_LEVEL_1 + level_2_payments*PRANA_LEVEL_2 + level_3_payments*PRANA_LEVEL_3}"

  end

  #OMEIN 

  def self.omein_calculate_power_starts period_start, period_end 

  end

  def self.omein_get_active_cycles period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at between ? AND ?", COMPANY_OMEIN, period_start, period_end).order("external_id desc").uniq

    puts "#{users.count} usuarios con consumo de Omein en el periodo #{period_start} - #{period_end}"

    users_with_active_cycle = []

    users.each do |user|

      if not user.omein_active_for_period period_start, period_end 
        next
      end

      placement_downlines = user.placement_downlines 

      if placement_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START

        active_downlines = []
        inactive_downlines = []
        
        placement_downlines.each do |downline|

          active_in_period = downline.omein_active_for_period period_start, period_end

          if active_in_period
            active_downlines << downline
          else
            inactive_downlines << downline
          end
        end

        if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
          # Active Cycle eligible 
          users_with_active_cycle << user
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, COMPANY_OMEIN
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
              # Active Cycle eligible
              users_with_active_cycle << user
              break          
            end
            
          end
        end
      end
    end

    return users_with_active_cycle
    
  end

  def self.omein_calculate_ranks period_start, period_end

    users_with_active_cycle = Payment.omein_get_active_cycles period_start, period_end

    users_with_active_cycle.each do |user|
        
      group_volume = user.get_group_volume period_start, period_end

      if group_volume 

      end

    end

  end

  def self.omein_calculate_royalties period_start, period_end

  end
  
end
