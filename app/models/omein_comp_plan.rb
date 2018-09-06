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
  
  def self.calculate_active_cycles period_start, period_end

    users = User.joins(:orders => :items).where("items.company = ? AND orders.created_at between ? AND ?", COMPANY_OMEIN, period_start, period_end).order("external_id desc").uniq

    users_with_active_cycle_and_vg = []

    users.each do |user|

      if not user.omein_active_for_period period_start, period_end 
        next
      end

      placement_downlines = user.placement_downlines 

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
          users_with_active_cycle_and_vg << {user: user, vg: user.omein_get_group_volume(period_start, period_end) }
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, COMPANY_OMEIN
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_ACTIVE_CYCLE
              # Active Cycle eligible
              users_with_active_cycle_and_vg << {user: user, vg: (user.omein_get_group_volume period_start, period_end) }
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
        end

      end

    end

    return sevenks_with_vg

  end
  
  def self.calculate_ten_ks period_start, period_end, threeks, sevenks_with_vg

    tenks_with_vg = []

    sevenks_with_vg.each do |sevenk_with_vg|

      if sevenk_with_vg[:vg] >= TENK_VOLUME

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
        end

      end

    end

    return fiftyks_with_vg
    
  end

  def self.calculate_ranks period_start, period_end

    ranks = {}

    #Active Cycle
    users_with_active_cycle_and_vg = OmeinCompPlan.calculate_active_cycles period_start, period_end

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
  
  def self.calculate_power_starts period_start, period_end 

  end

  def self.calculate_royalties period_start, period_end

  end

end
