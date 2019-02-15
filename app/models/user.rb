class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :roles  
  has_and_belongs_to_many :shipping_addresses
  has_and_belongs_to_many :orders
  has_and_belongs_to_many :payments
  has_many :summaries
  has_many :emails
  has_many :invitations
  has_and_belongs_to_many :contributed_payments, class_name: 'Payment', join_table: 'from_users_payments', foreign_key: 'from_user_id'

  after_create :send_confirmation_email

  validates :max_rank, inclusion: {in: OmeinCompPlan::RANKS }  

  accepts_nested_attributes_for :shipping_addresses, allow_destroy: true  
  
  scope :by_external_id, -> (external_id){where(external_id: external_id)}  
  scope :with_max_id, -> {order(external_id: :desc).limit(1).first}
  
  def role?(role)
    return !!self.roles.find_by_name(role)
  end

  def self.confirm_by_token confirmation_token
    user = User.find_by_confirmation_token(confirmation_token)
    if user
      user.confirmed_at = Time.zone.now
      user.save!
    end
    return user
  end

  def register token = nil
    user = User.find_by_email(self.email)
    unless user
      if token
        if self.external_id == self.sponsor_external_id or self.external_id == self.placement_external_id
          self.errors.add(:registration, "Tu ID de Futura no puede ser igual que el de tu auspiciador.")
          false
        elsif User.where("external_id = ?", self.external_id).count >= 1
          self.errors.add(:registration, "Tu ID de Futura ya está siendo usado por alguien más, por favor escríbenos a admin@futuranetwork.com")
          false
        else
          invitations = Invitation.where("token = ? and used = ?", token, false)
          if invitations.size == 1
            if not (invitations.first.user.external_id == self.sponsor_external_id or invitations.first.user.external_id == self.placement_external_id)
              self.errors.add(:registration, "El ID de Futura en patrocinio o colocación debe ser el de la persona que te mandó la invitación.")
              false
            else
              invitations.first.update_attribute("used", true)
              #TODO: Check if needed in production
              self.send_confirmation_instructions
              true
            end
          else
            self.errors.add(:registration, "Necesitas una invitación válida para poderte registrar. Solicítala a tu upline.")
            false
          end
        end
      else
        self.send_confirmation_instructions
        true
      end
    else
      self.errors.add(:registration, "Ya existe un usuario registrado con ese correo electrónico.")
      false
    end
  end
  
  def placement_downlines
    User.where(placement_external_id: self.external_id)
  end

  def placement_upline
    User.find_by_external_id(self.placement_external_id)
  end

  def sponsor_downlines
    User.where(sponsor_external_id: self.external_id)
  end

  def sponsor_upline
    User.find_by_external_id(self.sponsor_external_id)
  end

  def omein_active_for_period period_start, period_end, min_volume = OmeinCompPlan::MIN_VOLUME

    omein_volume = self.omein_get_personal_volume period_start, period_end 

    if omein_volume < min_volume
      return false
    else
      return true
    end
    
  end

  #TODO: verify registration_paid in PRANA by checking ODERS with item 'INSCRIPCION' and adding a field in users named registration_paid
  def prana_active_for_period period_start, period_end, verify_min_volume_in_omein = false 

    prana_volume = self.prana_get_personal_volume period_start, period_end

    if prana_volume < PranaCompPlan::MIN_VOLUME
      return false
    end

    if verify_min_volume_in_omein
      return self.omein_active_for_period period_start, period_end, OmeinCompPlan::MAX_VOLUME
    else 
      return true
    end

  end

  def prana_commissionable_for_period period_start, period_end

    prana_volume = self.prana_get_personal_volume period_start, period_end

    if prana_volume < PranaCompPlan::MIN_VOLUME
      return false
    else
      return true
    end

  end

  def get_personal_volume_detail period_start, period_end, company
    user_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?", 
                                                        company, period_start, period_end).order(created_at: :asc).uniq

    return Order.get_volume_detail user_orders
  end

  def get_personal_volume period_start, period_end, company
    get_personal_volume_detail(period_start, period_end, company)[:total_volume]    
  end

  def omein_get_personal_volume period_start, period_end

    get_personal_volume period_start, period_end, OmeinCompPlan::COMPANY_OMEIN
    
  end

  def prana_get_personal_volume period_start, period_end
    
    get_personal_volume period_start, period_end, PranaCompPlan::COMPANY_PRANA 
    
  end

  def omein_get_power_start_volume period_start, period_end, company = OmeinCompPlan::COMPANY_OMEIN 

    previous_omein_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at < ?", company, period_start).uniq

    if previous_omein_orders.count > 0
      return {items: [], total_volume: 0}
    else
      current_omein_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?", 
                                                       company, period_start, period_end).order(created_at: :asc).uniq
      
      return Order.get_volume_detail [current_omein_orders.first]
    end

  end

  def omein_get_commissionable_volume period_start, period_end, company = OmeinCompPlan::COMPANY_OMEIN

    #return self.omein_get_personal_volume period_start, period_end

    #check if it is the first order from the user
    if self.created_at < period_start
      
      #previous_omein_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at < ?", company, period_start)

      #has previous orders registered
      #if previous_omein_orders.count > 0
      #  return self.omein_get_personal_volume period_start, period_end
      #doesn't have previous orderes registered, but it will be count 100% as VG for now
      #else
      #  return self.omein_get_personal_volume period_start, period_end
      #end
      
      return self.get_personal_volume_detail period_start, period_end, company
      
    else

      current_omein_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at >= ? AND orders.created_at < ?", 
                                                       company, period_start, period_end).uniq

      return Order.get_volume_detail_avoid_first_order current_omein_orders
       
    end

  end

  def get_group_volume period_start, period_end, company

    downlines = self.placement_downlines

    if downlines.count == 0
      
      volume = self.get_personal_volume period_start, period_end, company 
      puts "Usuario #{self.external_id} con #{volume} VP" if volume > 0
      return volume

    else

      volume = 0

      downlines.each do |downline|
        volume += downline.get_group_volume period_start, period_end, company
      end

      personal_volume = get_personal_volume period_start, period_end, company 
      volume += personal_volume
      
      puts "Usuario #{self.external_id} con #{personal_volume} VP" if personal_volume > 0 
      return volume

    end

  end

  def omein_get_group_volume period_start, period_end
    
    get_group_volume period_start, period_end, OmeinCompPlan::COMPANY_OMEIN
    
  end

  def prana_get_group_volume period_start, period_end
    
    get_group_volume period_start, period_end, PranaCompPlan::COMPANY_PRANA
    
  end

  def search_qualified_downlines qualified_users, root_tree, leg_position = nil

    downlines = self.placement_downlines

    if downlines.count == 0
      return root_tree
    else
      downlines.each_with_index {|user, index|

        if leg_position
          index = leg_position
        else
          root_tree[index] = []
        end

        is_qualified_downline = qualified_users.include? user

        if is_qualified_downline
          root_tree[index] << user
        end

        root_tree = user.search_qualified_downlines (qualified_users - [user]), root_tree, index

      }
    end

    return root_tree

  end

  def self.check_activity_recursive_downline inactive_downline, period_start, period_end, company

    downlines = inactive_downline.placement_downlines

    if downlines.count == 0
      return nil
    else
      inactive_downlines = []
      downlines.each do |downline|

        if company == OmeinCompPlan::COMPANY_OMEIN
          active_in_period = downline.omein_active_for_period period_start, period_end 
        else
          active_in_period = downline.prana_active_for_period period_start, period_end, true
        end

        if active_in_period
          return downline
        else
          inactive_downlines << downline
        end
      end

      inactive_downlines.each do |inactive_downline|
        
        downline = User.check_activity_recursive_downline inactive_downline, period_start, period_end, company

        if downline
          return downline
        end
      end

      return nil
      
    end

  end 

  def self.prana_check_activity_recursive_upline_3_levels_no_compression upline, uplines_with_eligibility, period_start, period_end 


    if upline == nil or uplines_with_eligibility.count == 3
      return uplines_with_eligibility
    else

      eligible_for_payment = upline.prana_active_for_period period_start, period_end, true
      active_in_prana = upline.prana_active_for_period period_start, period_end, false 

      if active_in_prana
        uplines_with_eligibility << {upline: upline, eligible: eligible_for_payment}
      end
        
      if upline.placement_upline
        return User.prana_check_activity_recursive_upline_3_levels_no_compression(upline.placement_upline, uplines_with_eligibility,
                                                                                  period_start, period_end)
      else
        return uplines_with_eligibility
      end
    end

  end

  def self.omein_check_activity_recursive_upline_4_levels_compression upline, qualified_uplines, period_start, period_end

    if upline == nil or qualified_uplines.count == 4
      return qualified_uplines
    else

      if (upline.omein_active_for_period (period_end - 6.weeks), period_end, 200)
        qualified_uplines << upline
      else
        if upline.sponsor_upline
          return User.omein_check_activity_recursive_upline_4_levels_compression(upline.sponsor_upline, qualified_uplines, 
            period_start, period_end)
        else
          return qualified_uplines
        end
      end
    end
  end

  def self.omein_check_activity_recursive_upline_2_levels_compression upline, qualified_uplines, period_start, period_end

    if upline == nil or qualified_uplines.count == 2
      return qualified_uplines
    else

      if (upline.omein_active_for_period (period_end - 6.weeks), period_end, 100) and (qualified_uplines.count == 0)
        qualified_uplines << upline
      elsif (upline.omein_active_for_period (period_end - 6.weeks), period_end, 200) and (qualified_uplines.count == 1)
        qualified_uplines << upline
      end

      if upline.sponsor_upline
        return User.omein_check_activity_recursive_upline_2_levels_compression(upline.sponsor_upline, qualified_uplines, 
          period_start, period_end)
      else
        return qualified_uplines
      end
    end
  end

  def self.omein_check_activity_recursive_upline_9_levels_compression upline, qualified_uplines, qualified_ranks, period_start, period_end

    if upline == nil or qualified_uplines.count == 9
      return qualified_uplines
    else

      #search upline in eligible levels
      qualified_for_period = OmeinCompPlan.check_user_in_qualificated_ranks upline, qualified_ranks, qualified_uplines.count

      if qualified_for_period 
        qualified_uplines << upline
      end
        
      if upline.placement_upline
        return User.omein_check_activity_recursive_upline_9_levels_compression(upline.placement_upline, qualified_uplines, qualified_ranks, 
          period_start, period_end)
      else
        return qualified_uplines
      end
    end

  end 

  def self.check_tree_consistency_placement user 

    if user.external_id == 11
      #Se ha llegado al final del árbol
      return true
    else
      placement_upline = user.placement_upline
      if placement_upline
        return User.check_tree_consistency_placement placement_upline
      else
        puts "Árbol sin upline de colocación para el usuario con ID #{user.external_id}"
        return false
      end
    end

  end

  def self.check_tree_consistency_sponsor user 

    if user.external_id == 11
      #Se ha llegado al final del árbol
      return true
    else
      sponsor_upline = user.sponsor_upline
      if sponsor_upline
        return User.check_tree_consistency_sponsor sponsor_upline
      else
        puts "Árbol sin upline de patrocinio para el usuario con ID #{user.external_id}"
        return false
      end
    end

  end

  def self.update_summaries period_start, period_end
    
    #users = User.joins(:orders => :items).where("orders.created_at >= ? AND orders.created_at < ?", period_start,
    #                                            period_end,).order("external_id desc").uniq

    User.all.each do |user|

      omein_vp = user.omein_get_personal_volume(period_start, period_end) 
      omein_vg = user.omein_get_group_volume(period_start, period_end)
      prana_vp = user.prana_get_personal_volume(period_start, period_end)
      prana_vg = user.prana_get_group_volume(period_start, period_end)

      Summary.omein_populate user, period_start.beginning_of_month,  (period_start + 1.month), omein_vp, omein_vg, nil
      Summary.prana_populate user, period_start.beginning_of_month,  (period_start + 1.month), prana_vp, prana_vg
      
    end

  end

  private

  def send_confirmation_email
    self.send_confirmation_instructions
  end
  
end
