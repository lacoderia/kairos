class PranaCompPlan

  COMPANY_PRANA = "PRANA"
  
  QUICK_START = 4000.00
  DEFERRED_QUICK_START = 2000.00
  LEVEL_1 = 200.00
  LEVEL_2 = 600.00
  LEVEL_3 = 200.00
  ACTIVE_DOWNLINES_FOR_QUICK_START = 3

  MIN_VOLUME = 200

  def self.calculate_quick_starts period_start, period_end, launch_event = false

    users = User.joins(:orders => :items).where("users.quick_start_paid = ? AND orders.created_at >= ? AND orders.created_at < 
                                                ? AND items.company = ? AND orders.order_status != ?", false, period_start - 1.month,
                                                period_end, COMPANY_PRANA, "VALIDATING").order("external_id desc").uniq

    
    quick_start_payments = 0

    users.each do |user|

      deferred_user = false
      user_sign_up_in_prana = user.created_at.beginning_of_day 
      user_deadline = user_sign_up_in_prana.end_of_day + 1.month 

      #deferred user
      if period_end.beginning_of_day > user_deadline

        if (not user.prana_active_for_period period_start.beginning_of_month,  period_start.beginning_of_month + 1.month, true) 
          next
        end

        deferred_user = true

      end
      
      downlines = user.placement_downlines 

      if downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
        active_downlines = []
        inactive_downlines = []
        not_deferred_downlines = 0 
        
        downlines.each do |downline|

          if deferred_user

            if downline.prana_active_for_period period_start.beginning_of_month, period_start.beginning_of_month + 1.month, true
              active_downlines << downline 
            else
              inactive_downlines << downline 
            end

          else

            if downline.prana_active_for_period user_sign_up_in_prana, user_deadline, true
              active_downlines << downline 

              # flag active downlines that have created_at of downline outside the deadline of the upline 
              if not (downline.created_at.beginning_of_day < user_sign_up_in_prana or downline.created_at.beginning_of_day >= user_deadline)
                not_deferred_downlines += 1
              end

            else
              inactive_downlines << downline 
            end

          end
         
        end

        if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START

          if deferred_user
            Payment.prana_add_deferred_quick_start user, period_start, period_end, active_downlines
          else

            if not_deferred_downlines >= ACTIVE_DOWNLINES_FOR_QUICK_START
              Payment.prana_add_quick_start user, period_start, period_end, active_downlines
            else
              puts "pago diferido porque uno o más downlines de los downlines son diferidos"
              Payment.prana_add_deferred_quick_start user, period_start, period_end, active_downlines
            end

          end
          puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period_start} - #{period_end}"
          quick_start_payments += 1

        else

          inactive_downlines.each do |inactive_downline|

            if deferred_user
              downline = User.check_activity_recursive_downline inactive_downline, period_start.beginning_of_month,
                period_start.beginning_of_month + 1.month, COMPANY_PRANA
            else
              downline = User.check_activity_recursive_downline inactive_downline, user_sign_up_in_prana, user_deadline, COMPANY_PRANA
            end

            if downline
              active_downlines << downline

              if not deferred_user
                # flag active downlines that have created_at of downline outside the deadline of the upline 
                if not (downline.created_at.beginning_of_day < user_sign_up_in_prana or downline.created_at.beginning_of_day >= user_deadline)
                  not_deferred_downlines += 1
                end
              end

            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START

              if deferred_user
                Payment.prana_add_deferred_quick_start user, period_start, period_end, active_downlines
              else

                if not_deferred_downlines >= ACTIVE_DOWNLINES_FOR_QUICK_START
                  Payment.prana_add_quick_start user, period_start, period_end, active_downlines
                else
                  puts "pago diferido porque uno o más downlines de los downlines son diferidos"
                  Payment.prana_add_deferred_quick_start user, period_start, period_end, active_downlines
                end

              end
              puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period_start} - #{period_end}"
              quick_start_payments += 1
              break          
            end
          end
        end
      end
    end

    puts "#{quick_start_payments} pagos de quick start en el periodo #{period_start} - #{period_end}"

  end

  def self.calculate_royalties period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?
                                                AND orders.order_status != ?", COMPANY_PRANA, period_start, period_end, 
                                               "VALIDATING").order("external_id desc").uniq

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

      if vp < PranaCompPlan::MIN_VOLUME
        next
      end

      if user.placement_upline
        
        uplines = User.prana_check_activity_recursive_upline_3_levels_no_compression(user.placement_upline, [],
                                                                                            period_start, period_end)

        puts "pagos del usuario #{user.email}"

        if uplines[0] and uplines[0][:eligible]
          Payment.prana_add_payment uplines[0][:upline], period_start, period_end, [user], 1, vp
          level_1_payments += 1
          puts "pago de nivel 1 al usuario #{uplines[0][:upline].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[1] and uplines[1][:eligible]
          Payment.prana_add_payment uplines[1][:upline], period_start, period_end, [user], 2, vp
          level_2_payments += 1 
          puts "pago de nivel 2 al usuario #{uplines[1][:upline].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[2] and uplines[2][:eligible]
          Payment.prana_add_payment uplines[2][:upline], period_start, period_end, [user], 3, vp
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
