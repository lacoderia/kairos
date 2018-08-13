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

    users_with_active_cycle_and_vg = []

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
          users_with_active_cycle_and_vg << {user: user, vg: user.get_group_volume(period_start, period_end) }
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, COMPANY_OMEIN
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
              # Active Cycle eligible
              users_with_active_cycle_and_vg << {user: user, vg: (user.get_group_volume period_start, period_end) }
              break          
            end
            
          end
        end
      end
    end

    return users_with_active_cycle_and_vg
    
  end

  def self.omein_calculate_ranks period_start, period_end

    users_with_active_cycle_and_vg = Payment.omein_get_active_cycles period_start, period_end
    oneks_with_vg = []
    oneks = []

    users_with_active_cycle_and_vg.each do |user_with_vg|

      if user_with_vg[:vg] > 1000
        oneks_with_vg << user_with_vg
        oneks << user_with_vg[:user]
      end
      
    end

    #we subtract the calculated 1ks and above ranks
    users_with_active_cycle_and_vg -= oneks_with_vg

    threeks_with_vg = []
    threeks = []

    oneks_with_vg.each do |onek_with_vg|

      if onek_with_vg[:vg] > 3000

        result_tree = onek_with_vg[:user].search_qualified_downlines (oneks - [onek_with_vg[:user]]), {}, nil

        #two 1ks in different legs to qualify 3k
        eligible_1ks = 0
        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count > 0
            eligible_1ks += 1
            next
          end
        }
        
        if eligible_1ks >= 2
          threeks_with_vg << onek_with_vg
          threeks << onek_with_vg[:user]
        end

      end

    end
    
    #we subtract the calculated 3ks and above ranks
    oneks_with_vg -= threeks_with_vg

    sevenks_with_vg = []

    threeks_with_vg.each do |threek_with_vg|

      if threek_with_vg[:vg] > 7000

        result_tree = threek_with_vg[:user].search_qualified_downlines (threeks - [threek_with_vg[:user]]), {}, nil

        #two 3ks in different legs to qualify 7k
        eligible_3ks = 0
        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count > 0
            eligible_3ks += 1
            next
          end
        }
        
        if eligible_3ks >= 2
          sevenks_with_vg << threek_with_vg
        end

      end

    end

    #we subtract the calculated 7ks and above ranks
    threeks_with_vg -= sevenks_with_vg

    tenks_with_vg = []

    sevenks_with_vg.each do |sevenk_with_vg|

      if sevenk_with_vg[:vg] > 10000

        #we use the threeks as the original set
        result_tree = sevenk_with_vg[:user].search_qualified_downlines (threeks - [sevenk_with_vg[:user]]), {}, nil

        #three 3ks, max 2 in a single group
        eligible_3ks = 0

        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count >= 2
            eligible_3ks += 2
          else
            eligible_3ks += users_with_vg.count
          end
          next
        }
        
        if eligible_3ks >= 3
          tenks_with_vg << sevenk_with_vg
        end

      end

    end
    
    #we subtract the calculated 10ks and above ranks
    sevenks_with_vg -= tenks_with_vg

    twentyks_with_vg = []

    tenks_with_vg.each do |tenk_with_vg|

      if tenk_with_vg[:vg] > 20000

        #we use the threeks as the original set
        result_tree = tenk_with_vg[:user].search_qualified_downlines (threeks - [tenk_with_vg[:user]]), {}, nil

        #five 3ks, max 3 in a single group
        eligible_3ks = 0

        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count >= 3
            eligible_3ks += 3
          else
            eligible_3ks += users_with_vg.count
          end
          next
        }
        
        if eligible_3ks >= 5
          twentyks_with_vg << tenk_with_vg
        end

      end

    end
    
    #we subtract the calculated 20ks and above ranks
    tenks_with_vg -= twentyks_with_vg

    #todo: return the resultsets
    byebug
  end

  def self.omein_calculate_royalties period_start, period_end

  end
  
end
