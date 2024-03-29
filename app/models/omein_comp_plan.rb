class OmeinCompPlan 

  COMPANY_OMEIN = "OMEIN"
  
  ONEK_VOLUME = 1000 
  THREEK_VOLUME = 3000 
  SEVENK_VOLUME = 7000 
  TENK_VOLUME = 10000 
  TWENTYK_VOLUME = 20000 
  THRITYK_VOLUME = 30000 
  FIFTYK_VOLUME = 50000 
  
  ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE = 3
  MAX_VOLUME = 200
  MIN_VOLUME = 100
  
  POWER_START_25 = 0.25
  POWER_START_15 = 0.15

  SELLING_BONUS_20 = 0.20
  SELLING_BONUS_10 = 0.10
  SELLING_BONUS_4 = 0.04

  LEVEL_1 = 0.02
  LEVEL_2 = 0.04
  LEVEL_3 = 0.06
  LEVEL_4 = 0.08
  LEVEL_5 = 0.04
  LEVEL_6 = 0.04
  LEVEL_7 = 0.04
  LEVEL_8 = 0.04
  LEVEL_9 = 0.06

  COMMISSIONABLE_VALUE_AYNI = 1107.00
  COMMISSIONABLE_VALUE_MONK = 308.00

  LEVELS_PER_RANK = {
    active_with_vg: [0, 1, 2],
    ac_with_vg: [0, 1, 2],
    oneks_with_vg: [0, 1, 2, 3],
    threeks_with_vg: [0, 1, 2, 3],
    sevenks_with_vg: [0, 1, 2, 3, 4],
    tenks_with_vg: [0, 1, 2, 3, 4],
    twentyks_with_vg: [0, 1, 2, 3, 4, 5, 6],
    thirtyks_with_vg: [0, 1, 2, 3, 4, 5, 6, 7],
    fiftyks_with_vg: [0, 1, 2, 3, 4, 5, 6, 7, 8]
  }

  RANKS = ["N/A", "Empresario", "1K", "3K", "7K", "10K", "20K", "30K", "50K", "100K", "200K", "500K"]
  
  def self.calculate_active_for_royalties period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?  AND orders.order_status != ?", COMPANY_OMEIN, period_start, period_end, "VALIDATING").order("external_id desc").uniq

    users_active_for_royalties = []

    users.each do |user|

      vp = user.omein_get_personal_volume(period_start, period_end) 
      vg = user.omein_get_group_volume(period_start, period_end)
      
      if not user.omein_active_for_period period_start, period_end 
        Summary.omein_populate user, period_start, period_end, vp, vg, "N/A"
        next
      else
        users_active_for_royalties << {user: user, vp: vp, vg: vg}
        new_rank = RANKS.index(user.max_rank) < RANKS.index("Empresario") 
        user.update_attribute(:max_rank, "Empresario") if new_rank 
        Summary.omein_populate user, period_start, period_end, vp, vg, "Empresario", new_rank
      end
      
    end

    return users_active_for_royalties

  end

  def self.calculate_active_cycles period_start, period_end, users_active_for_royalties
    
    users_with_active_cycle_and_vg = []

    users_active_for_royalties.each do |user_with_vg|

      placement_downlines = user_with_vg[:user].placement_downlines 

      if placement_downlines.count >= ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE

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

        if active_downlines.count >= ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE
          # Active Cycle eligible 
          users_with_active_cycle_and_vg << {user: user_with_vg[:user], vp: user_with_vg[:vp], vg: user_with_vg[:vg]}
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, COMPANY_OMEIN
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE
              # Active Cycle eligible
              users_with_active_cycle_and_vg << {user: user_with_vg[:user], vp: user_with_vg[:vp], vg: user_with_vg[:vg]}
              break          
            end
            
          end
        end
      end

    end
    
    return users_with_active_cycle_and_vg

  end
 
  def self.calculate_one_ks period_start, period_end, users_with_active_cycle_and_vg
    
    oneks_with_vg = []
    oneks = []

    users_with_active_cycle_and_vg.each do |user_with_vg|

      if user_with_vg[:vg] >= ONEK_VOLUME
        oneks_with_vg << user_with_vg
        oneks << user_with_vg[:user]
        new_rank = RANKS.index(user_with_vg[:user].max_rank) < RANKS.index("1K") 
        Summary.omein_update user_with_vg[:user], period_start, period_end, {rank: "1K", new_rank: new_rank}
        user_with_vg[:user].update_attribute(:max_rank, "1K") if new_rank
      end
      
    end

    return [oneks, oneks_with_vg]

  end

  def self.calculate_three_ks period_start, period_end, oneks, oneks_with_vg 

    threeks_with_vg = []
    threeks = []

    oneks_with_vg.each do |onek_with_vg|

      if onek_with_vg[:vg] >= THREEK_VOLUME

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
          new_rank = RANKS.index(onek_with_vg[:user].max_rank) < RANKS.index("3K") 
          Summary.omein_update onek_with_vg[:user], period_start, period_end, {rank: "3K", new_rank: new_rank} 
          onek_with_vg[:user].update_attribute(:max_rank, "3K") if new_rank 
        end

      end

    end
    
    return [threeks, threeks_with_vg]

  end

  def self.calculate_seven_ks period_start, period_end, threeks, threeks_with_vg

    sevenks_with_vg = []

    threeks_with_vg.each do |threek_with_vg|

      if threek_with_vg[:vg] >= SEVENK_VOLUME

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
          new_rank = RANKS.index(threek_with_vg[:user].max_rank) < RANKS.index("7K") 
          Summary.omein_update threek_with_vg[:user], period_start, period_end, {rank: "7K", new_rank: new_rank} 
          threek_with_vg[:user].update_attribute(:max_rank, "7K") if new_rank 
        end

      end

    end

    return sevenks_with_vg

  end
  
  def self.calculate_ten_ks period_start, period_end, threeks, sevenks_with_vg

    tenks_with_vg = []

    sevenks_with_vg.each do |sevenk_with_vg|

      #we check that they have max volume to qualify 10k and above ranks
      if sevenk_with_vg[:vg] >= TENK_VOLUME and sevenk_with_vg[:vp] >= MAX_VOLUME

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
          new_rank = RANKS.index(sevenk_with_vg[:user].max_rank) < RANKS.index("10K") 
          Summary.omein_update sevenk_with_vg[:user], period_start, period_end, {rank: "10K", new_rank: new_rank} 
          sevenk_with_vg[:user].update_attribute(:max_rank, "10K") if new_rank 
        end

      end

    end

    return tenks_with_vg

  end

  def self.calculate_twenty_ks period_start, period_end, threeks, tenks_with_vg

    twentyks_with_vg = []

    tenks_with_vg.each do |tenk_with_vg|

      if tenk_with_vg[:vg] >= TWENTYK_VOLUME

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
          new_rank = RANKS.index(tenk_with_vg[:user].max_rank) < RANKS.index("20K") 
          Summary.omein_update tenk_with_vg[:user], period_start, period_end, {rank: "20K", new_rank: new_rank} 
          tenk_with_vg[:user].update_attribute(:max_rank, "20K") if new_rank 
        end

      end

    end

    return twentyks_with_vg

  end

  def self.calculate_thirty_ks period_start, period_end, threeks, twentyks_with_vg

    thirtyks_with_vg = []

    twentyks_with_vg.each do |twentyk_with_vg|

      if twentyk_with_vg[:vg] >= THRITYK_VOLUME

        #we use the threeks as the original set
        result_tree = twentyk_with_vg[:user].search_qualified_downlines (threeks - [twentyk_with_vg[:user]]), {}, nil

        #seven 3ks, max 4 in a single group
        eligible_3ks = 0

        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count >= 4
            eligible_3ks += 4
          else
            eligible_3ks += users_with_vg.count
          end
          next
        }
        
        if eligible_3ks >= 7
          thirtyks_with_vg << twentyk_with_vg
          new_rank = RANKS.index(twentyk_with_vg[:user].max_rank) < RANKS.index("30K") 
          Summary.omein_update twentyk_with_vg[:user], period_start, period_end, {rank: "30K", new_rank: new_rank} 
          twentyk_with_vg[:user].update_attribute(:max_rank, "30K") if new_rank 
        end

      end

    end

    return thirtyks_with_vg

  end

  def self.calculate_fifty_ks period_start, period_end, threeks, thirtyks_with_vg

    fiftyks_with_vg = []

    thirtyks_with_vg.each do |thirtyk_with_vg|

      if thirtyk_with_vg[:vg] >= FIFTYK_VOLUME

        #we use the threeks as the original set
        result_tree = thirtyk_with_vg[:user].search_qualified_downlines (threeks - [thirtyk_with_vg[:user]]), {}, nil

        #ten 3ks, max 5 in a single group
        eligible_3ks = 0

        result_tree.each_with_index {|users_with_vg, index|
          if users_with_vg.count >= 5
            eligible_3ks += 5
          else
            eligible_3ks += users_with_vg.count
          end
          next
        }
        
        if eligible_3ks >= 10
          fiftyks_with_vg << thirtyk_with_vg
          new_rank = RANKS.index(thirtyk_with_vg[:user].max_rank) < RANKS.index("50K") 
          Summary.omein_update thirtyk_with_vg[:user], period_start, period_end, {rank: "50K", new_rank: new_rank} 
          thirtyk_with_vg[:user].update_attribute(:max_rank, "50K") if new_rank 
        end

      end

    end

    return fiftyks_with_vg
    
  end

  def self.calculate_ranks period_start, period_end

    ranks = {}

    #Active Users  
    users_active_for_royalties = OmeinCompPlan.calculate_active_for_royalties period_start, period_end

    #Active Cycle
    users_with_active_cycle_and_vg = OmeinCompPlan.calculate_active_cycles period_start, period_end, users_active_for_royalties
    #we subtract the calculated AC and above ranks
    users_active_for_royalties -= users_with_active_cycle_and_vg
    ranks[:active_with_vg] = users_active_for_royalties

    #1ks
    oneks, oneks_with_vg = OmeinCompPlan.calculate_one_ks period_start, period_end, users_with_active_cycle_and_vg
    #we subtract the calculated 1ks and above ranks
    users_with_active_cycle_and_vg -= oneks_with_vg
    ranks[:ac_with_vg] = users_with_active_cycle_and_vg

    #3ks
    threeks, threeks_with_vg = OmeinCompPlan.calculate_three_ks period_start, period_end, oneks, oneks_with_vg        
    #we subtract the calculated 3ks and above ranks
    oneks_with_vg -= threeks_with_vg
    ranks[:oneks_with_vg] = oneks_with_vg

    #7ks
    sevenks_with_vg = OmeinCompPlan.calculate_seven_ks period_start, period_end, threeks, threeks_with_vg 
    #we subtract the calculated 7ks and above ranks
    threeks_with_vg -= sevenks_with_vg
    ranks[:threeks_with_vg] = threeks_with_vg

    #10ks
    tenks_with_vg = OmeinCompPlan.calculate_ten_ks period_start, period_end, threeks, sevenks_with_vg
    #we subtract the calculated 10ks and above ranks
    sevenks_with_vg -= tenks_with_vg
    ranks[:sevenks_with_vg] = sevenks_with_vg

    #20ks
    twentyks_with_vg = OmeinCompPlan.calculate_twenty_ks period_start, period_end, threeks, tenks_with_vg
    #we subtract the calculated 20ks and above ranks
    tenks_with_vg -= twentyks_with_vg
    ranks[:tenks_with_vg] = tenks_with_vg

    #30ks
    thirtyks_with_vg = OmeinCompPlan.calculate_thirty_ks period_start, period_end, threeks, twentyks_with_vg
    #we subtract the calculated 30ks and above ranks
    twentyks_with_vg -= thirtyks_with_vg
    ranks[:twentyks_with_vg] = twentyks_with_vg

    #50ks
    fiftyks_with_vg = OmeinCompPlan.calculate_fifty_ks period_start, period_end, threeks, thirtyks_with_vg
    #we subtract the calculated 50ks and above ranks
    thirtyks_with_vg -= fiftyks_with_vg
    ranks[:thirtyks_with_vg] = thirtyks_with_vg
    ranks[:fiftyks_with_vg] = fiftyks_with_vg

    return ranks

  end

  #WEEKLY PERIODS
  def self.calculate_selling_bonus period_start, period_end

    users = User.joins(:orders => :items).where("orders.created_at >= ? AND orders.created_at < ? AND items.company = ?
                                                AND orders.order_status != ?", (period_start - 1.week), period_end, COMPANY_OMEIN, 
                                                "VALIDATING").order("external_id desc").uniq

    base_payments = 0
    level_1_payments = 0
    level_2_payments = 0
    level_3_payments = 0
    level_4_payments = 0

    users.each do |user|

      if period_start.month != period_end.month
        total_pv_details = user.get_personal_volume_detail period_start.beginning_of_month, period_start.end_of_month, COMPANY_OMEIN
      else
        total_pv_details = user.get_personal_volume_detail period_start.beginning_of_month, period_end, COMPANY_OMEIN
      end
      total_pv = total_pv_details[:total_volume]
      
      if total_pv > MAX_VOLUME
      
        if period_start.month != period_end.month
          weekly_pv_details = user.get_personal_volume_detail period_start, period_start.end_of_month, COMPANY_OMEIN 
          delta_pv_details = user.get_personal_volume_detail period_start.beginning_of_month, period_start, COMPANY_OMEIN
        else
          if (period_start - 1.week).month != (period_end - 1.week).month
            weekly_pv_details = user.get_personal_volume_detail period_start.beginning_of_month, period_end, COMPANY_OMEIN 
            delta_pv_details = {total_volume: 0, items: []}
          else
            weekly_pv_details = user.get_personal_volume_detail period_start, period_end, COMPANY_OMEIN 
            delta_pv_details = user.get_personal_volume_detail period_start.beginning_of_month, period_start, COMPANY_OMEIN
          end
        end
        weekly_pv = weekly_pv_details[:total_volume] 
        delta_pv_total = delta_pv_details[:total_volume]
        
        #we pay all of the week
        if delta_pv_total >= MAX_VOLUME 
          selling_bonus_detail = weekly_pv_details
        #we pay the new week exceeding only the MAX VOLUME considering the previous orders
        else 

          remaining_points = MAX_VOLUME - delta_pv_total
          selling_bonus_detail = {items: [], total_volume: 0}

          if remaining_points < weekly_pv
            
            excedent_pv = weekly_pv - remaining_points

            if excedent_pv >= 100
              acc_volume = 0
              weekly_pv_details[:items].each do |item|
                acc_volume += item[:volume]
                if acc_volume >= remaining_points

                  partial_points = item[:volume] - remaining_points

                  #break items into smaller volume items
                  if partial_points > 0 and remaining_points != 0
                    (partial_points/100).times.each do |x|
                      base_100_item = Item.find_by_volume(100)                  
                      selling_bonus_detail[:items] << {id: base_100_item.id, volume: base_100_item.volume}
                      selling_bonus_detail[:total_volume] += base_100_item.volume
                    end
                    remaining_points = 0
                  elsif partial_points < 0 and remaining_points != 0
                    remaining_points -= item[:volume]
                  else
                    selling_bonus_detail[:items] << item
                    selling_bonus_detail[:total_volume] += item[:volume]
                  end
                end
              end
            end
          end
        end
                
        Payment.omein_add_selling_bonus_20 user, period_start, period_end, [user], selling_bonus_detail 
        base_payments += 1
        puts "pago de 20% al usuario #{user.email} en el periodo #{period_start} - #{period_end}"

        uplines = User.omein_check_activity_recursive_upline_4_levels_compression(user.sponsor_upline, [],
                                                                                            period_start, period_end)

        if uplines[0]
          Payment.omein_add_selling_bonus_10 uplines[0], period_start, period_end, [user], selling_bonus_detail 
          level_1_payments += 1
          puts "pago de 10% al usuario #{uplines[0].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[1]
          Payment.omein_add_selling_bonus_4 uplines[1], period_start, period_end, [user], selling_bonus_detail 
          level_2_payments += 1
          puts "pago de 4% al usuario #{uplines[1].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[2]
          Payment.omein_add_selling_bonus_4 uplines[2], period_start, period_end, [user], selling_bonus_detail 
          level_3_payments += 1
          puts "pago de 4% al usuario #{uplines[2].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[3]
          Payment.omein_add_selling_bonus_4 uplines[3], period_start, period_end, [user], selling_bonus_detail 
          level_4_payments += 1
          puts "pago de 4% al usuario #{uplines[3].email} en el periodo #{period_start} - #{period_end}"
        end

      end

    end

  end

  #WEEKLY PERIODS
  def self.calculate_power_starts period_start, period_end 

    users = User.joins(:orders => :items).where("users.created_at >= ? AND users.created_at < ? AND orders.created_at >= ? AND
                                                orders.created_at < ? AND items.company = ? AND orders.order_status != ?",
                                                period_start - 1.month, period_end, period_start, period_end, COMPANY_OMEIN,
                                               "VALIDATING").order("external_id desc").uniq

    puts "#{users.count} usuarios nuevos con consumo de #{COMPANY_OMEIN} en el periodo #{period_start} - #{period_end}"
    
    level_1_payments = 0
    level_2_payments = 0

    users.each do |user|

      power_start_volume_detail = user.omein_get_power_start_volume period_start, period_end

      uplines = User.omein_check_activity_recursive_upline_2_levels_compression(user.sponsor_upline, [],
                                                                                            period_start, period_end)
      
      if uplines[0]
        Payment.omein_add_power_start_25 uplines[0], period_start, period_end, [user], power_start_volume_detail 
        level_1_payments += 1
        puts "pago de 25% al usuario #{uplines[0].email} en el periodo #{period_start} - #{period_end}"
      end
      if uplines[1]
        Payment.omein_add_power_start_15 uplines[1], period_start, period_end, [user], power_start_volume_detail 
        level_2_payments += 1
        puts "pago de 15% al usuario #{uplines[1].email} en el periodo #{period_start} - #{period_end}"
      end

    end

    puts "#{level_1_payments} pagos de 25% en el periodo #{period_start} - #{period_end}"
    puts "#{level_2_payments} pagos de 15% en el periodo #{period_start} - #{period_end}"

  end

  def self.check_user_in_qualificated_ranks upline, qualified_ranks, qualified_uplines_count

    #search upline in qualified ranks

    rank = nil
    qualified_ranks.each do |key, users_with_vg|

      break if rank

      users_with_vg.each do |user_with_vg|
        
        if user_with_vg[:user] == upline
          rank = key
          break
        end

      end

    end

    if rank
      return LEVELS_PER_RANK[rank].include? qualified_uplines_count
    else
      return false
    end

  end

  def self.calculate_royalties period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?
                                                AND orders.order_status != ?", COMPANY_OMEIN, period_start, period_end, 
                                               "VALIDATING").order("external_id desc").uniq

    puts "#{users.count} usuarios con consumo de #{COMPANY_OMEIN} en el periodo #{period_start} - #{period_end}"

    level_1_payments = 0
    level_2_payments = 0
    level_3_payments = 0
    level_4_payments = 0
    level_5_payments = 0
    level_6_payments = 0
    level_7_payments = 0
    level_8_payments = 0
    level_9_payments = 0

    inactive_users = User.all - users 

    inactive_users.each do |inactive_user|
      vp = inactive_user.omein_get_personal_volume(period_start, period_end) 
      vg = inactive_user.omein_get_group_volume(period_start, period_end)
      Summary.omein_populate inactive_user, period_start, period_end, vp, vg, "N/A"
    end

    qualified_ranks = OmeinCompPlan.calculate_ranks period_start, period_end

    users.each do |user|

      if user.placement_upline

        commissionable_detail = user.omein_get_commissionable_volume period_start, period_end
        uplines = User.omein_check_activity_recursive_upline_9_levels_compression(user.placement_upline, [], qualified_ranks,
                                                                                            period_start, period_end)

        puts "pagos del usuario #{user.email}"

        if uplines[0]
          Payment.omein_add_payment uplines[0], period_start, period_end, [user], 1, commissionable_detail
          level_1_payments += 1
          puts "pago de nivel 1 al usuario #{uplines[0].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[1]
          Payment.omein_add_payment uplines[1], period_start, period_end, [user], 2, commissionable_detail
          level_2_payments += 1
          puts "pago de nivel 2 al usuario #{uplines[1].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[2] 
          Payment.omein_add_payment uplines[2], period_start, period_end, [user], 3, commissionable_detail
          level_3_payments += 1
          puts "pago de nivel 3 al usuario #{uplines[2].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[3]
          Payment.omein_add_payment uplines[3], period_start, period_end, [user], 4, commissionable_detail
          level_4_payments += 1
          puts "pago de nivel 4 al usuario #{uplines[3].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[4]
          Payment.omein_add_payment uplines[4], period_start, period_end, [user], 5, commissionable_detail
          level_5_payments += 1
          puts "pago de nivel 5 al usuario #{uplines[4].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[5]
          Payment.omein_add_payment uplines[5], period_start, period_end, [user], 6, commissionable_detail
          level_6_payments += 1
          puts "pago de nivel 6 al usuario #{uplines[5].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[6]
          Payment.omein_add_payment uplines[6], period_start, period_end, [user], 7, commissionable_detail
          level_7_payments += 1
          puts "pago de nivel 7 al usuario #{uplines[6].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[7]
          Payment.omein_add_payment uplines[7], period_start, period_end, [user], 8, commissionable_detail
          level_8_payments += 1
          puts "pago de nivel 8 al usuario #{uplines[7].email} en el periodo #{period_start} - #{period_end}"
        end
        if uplines[8]
          Payment.omein_add_payment uplines[8], period_start, period_end, [user], 9, comissionable_volume
          level_9_payments += 1
          puts "pago de nivel 9 al usuario #{uplines[8].email} en el periodo #{period_start} - #{period_end}"
        end
              
      end

    end
    
    puts "#{level_1_payments} pagos de nivel 1 en el periodo #{period_start} - #{period_end}"
    puts "#{level_2_payments} pagos de nivel 2 en el periodo #{period_start} - #{period_end}"
    puts "#{level_3_payments} pagos de nivel 3 en el periodo #{period_start} - #{period_end}"
    puts "#{level_4_payments} pagos de nivel 4 en el periodo #{period_start} - #{period_end}"
    puts "#{level_5_payments} pagos de nivel 5 en el periodo #{period_start} - #{period_end}"
    puts "#{level_6_payments} pagos de nivel 6 en el periodo #{period_start} - #{period_end}"
    puts "#{level_7_payments} pagos de nivel 7 en el periodo #{period_start} - #{period_end}"
    puts "#{level_8_payments} pagos de nivel 8 en el periodo #{period_start} - #{period_end}"
    puts "#{level_9_payments} pagos de nivel 9 en el periodo #{period_start} - #{period_end}"

  end

end
