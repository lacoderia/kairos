class PranaCompPlan

  COMPANY_PRANA = "PRANA"
  
  QUICK_START = 4000.00
  LEVEL_1 = 200.00
  LEVEL_2 = 600.00
  LEVEL_3 = 200.00
  ACTIVE_DOWNLINES_FOR_QUICK_START = 3

  
  def self.calculate_quick_starts period_start, period_end, launch_event

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

  def self.calculate_royalties period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at between ? AND ?", COMPANY_PRANA, period_start, period_end).order("external_id desc").uniq

    puts "#{users.count} usuarios con consumo de #{COMPANY_PRANA} en el periodo #{period_start} - #{period_end}"

    level_1_payments = 0
    level_2_payments = 0
    level_3_payments = 0
    
    inactive_users = User.all - users 

    inactive_users.each do |inactive_user|
      vp = inactive_user.prana_get_personal_volume(period_start, period_end) 
      vg = inactive_user.prana_get_group_volume(period_start, period_end)
      Summary.prana_populate inactive_user, period_start, period_end, vp, vg
    end

    users.each do |user|
              
      vp = user.prana_get_personal_volume(period_start, period_end) 
      vg = user.prana_get_group_volume(period_start, period_end)

      Summary.prana_populate user, period_start, period_end, vp, vg

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
    
    puts "#{level_1_payments} pagos de nivel 1 en el periodo #{period_start} - #{period_end}"
    puts "#{level_2_payments} pagos de nivel 2 en el periodo #{period_start} - #{period_end}"
    puts "#{level_3_payments} pagos de nivel 3 en el periodo #{period_start} - #{period_end}"
    puts "TOTAL: #{level_1_payments*LEVEL_1 + level_2_payments*LEVEL_2 + level_3_payments*LEVEL_3}"

  end
  
end
