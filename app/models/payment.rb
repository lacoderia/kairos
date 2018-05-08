class Payment < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :from_users, join_table: 'from_users_payments' , association_foreign_key: 'from_user_id', class_name: 'User' 

  QUICK_START = 4000.00
  LEVEL_1 = 200.00
  LEVEL_2 = 600.00
  LEVEL_3 = 200.00
  ACTIVE_DOWNLINES_FOR_QUICK_START = 3

  PAYMENT_TYPES = [
    'QUICK_START',
    'LEVEL_1',
    'LEVEL_2',
    'LEVEL_3'
  ]
  
  validates :payment_type, inclusion: {in: PAYMENT_TYPES}

  def self.add_quick_start user, period, from_users
    user.payments << Payment.create!(payment_type: 'QUICK_START', amount: QUICK_START , term_paid: period, from_users: from_users)
    user.update_attribute(:quick_start_paid, true)
  end

  def self.add_level_1 user, period, from_users
    user.payments << Payment.create!(payment_type: 'LEVEL_1', amount: LEVEL_1 , term_paid: period, from_users: from_users)
  end

  def self.add_level_2 user, period, from_users
    user.payments << Payment.create!(payment_type: 'LEVEL_2', amount: LEVEL_2 , term_paid: period, from_users: from_users)
  end

  def self.add_level_3 user, period, from_users
    user.payments << Payment.create!(payment_type: 'LEVEL_3', amount: LEVEL_3 , term_paid: period, from_users: from_users)
  end

  def self.calculate_quick_starts period

    users = User.joins(:orders).where("orders.description = ? and users.quick_start_paid = ?", period, false)
    puts "#{users.count} usuarios con consumo en el periodo #{period}"
    
    quick_start_payments = 0

    users.each do |user|
      downlines = user.placement_downlines 
      if downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
        active_downlines = []
        inactive_downlines = []
        
        downlines.each do |downline|
          orders_in_period = downline.orders.where("description = ?", period).count
          if orders_in_period > 0
            active_downlines << downline
          else
            inactive_downlines << downline            
          end
        end

        if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
          Payment.add_quick_start user, period, active_downlines
          puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period}"
          quick_start_payments += 1
        else
          inactive_downlines.each do |inactive_downline|
            downline = User.check_activity_recursive_downline inactive_downline, period
            if downline
              active_downlines << downline
            end

            if active_downlines.count >= ACTIVE_DOWNLINES_FOR_QUICK_START
              Payment.add_quick_start user, period, active_downlines
              puts "pago de powerstart activo al usuario #{user.email} en el periodo #{period}"
              quick_start_payments += 1
              break          
            end
          end
        end

      end
    end

    puts "#{quick_start_payments} pagos de power start en el periodo #{period}"

  end

  def self.calculate_royalties period

    users = User.joins(:orders).where("orders.description = ?", period)
    puts "#{users.count} usuarios con consumo en el periodo #{period}"

    level_1_payments = 0
    level_2_payments = 0
    level_3_payments = 0

    users.each do |user|

      if user.placement_upline
        active_uplines = User.check_activity_recursive_upline_3_levels user.placement_upline, [], period

        puts "pagos del usuario #{user.email}"

        if active_uplines[0]
          Payment.add_level_1 active_uplines[0], period, [user]
          level_1_payments += 1
          puts "pago de nivel 1 al usuario #{active_uplines[0].email} en el periodo #{period}"
        end
        if active_uplines[1]
          Payment.add_level_2 active_uplines[1], period, [user]
          level_2_payments += 1 
          puts "pago de nivel 2 al usuario #{active_uplines[1].email} en el periodo #{period}"
        end
        if active_uplines[2]
          Payment.add_level_3 active_uplines[2], period, [user]
          level_3_payments += 1 
          puts "pago de nivel 3 al usuario #{active_uplines[2].email} en el periodo #{period}"
        end
      
      end

    end
    
    puts "#{level_1_payments} pagos de nivel 1 start en el periodo #{period}"
    puts "#{level_2_payments} pagos de nivel 2 start en el periodo #{period}"
    puts "#{level_3_payments} pagos de nivel 3 start en el periodo #{period}"
    puts "TOTAL: #{level_1_payments*LEVEL_1 + level_2_payments*LEVEL_2 + level_3_payments*LEVEL_3}"

  end
  
end
