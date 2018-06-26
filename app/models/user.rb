class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable#, :confirmable
  
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :roles  
  has_and_belongs_to_many :shipping_addresses
  has_and_belongs_to_many :orders
  has_and_belongs_to_many :payments
  has_many :emails
  has_many :invitations
  has_and_belongs_to_many :contributed_payments, class_name: 'Payment', join_table: 'from_users_payments', foreign_key: 'from_user_id'

  scope :by_external_id, -> (external_id){where(external_id: external_id)}  
  
  def role?(role)
    return !!self.roles.find_by_name(role)
  end

  def register token = nil
    user = User.find_by_email(self.email)
    unless user
      if token
        if self.external_id == self.sponsor_external_id or self.external_id == self.placement_external_id
          self.errors.add(:registration, "Tu ID de PRANA no puede ser igual que el de tu auspiciador.")
          false
        elsif User.where("external_id = ?", self.external_id).count >= 1
          self.errors.add(:registration, "Tu ID de PRANA ya está siendo usado por alguien más, por favor escríbenos a contacto@prana.mx")
          false
        else
          invitations = Invitation.where("token = ? and used = ?", token, false)
          if invitations.size == 1
            if not (invitations.first.user.external_id == self.sponsor_external_id or invitations.first.user.external_id == self.placement_external_id)
              self.errors.add(:registration, "El ID de PRANA en patrocinio o colocación debe ser el de la persona que te mandó la invitación.")
              false
            else
              invitations.first.update_attribute("used", true)
              #TODO: Check if needed in production
              #self.send_confirmation_instructions
              true
            end
          else
            self.errors.add(:registration, "Necesitas una invitación válida para poderte registrar. Solicítala a tu upline.")
            false
          end
        end
      else
        #self.send_confirmation_instructions
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

  def omein_active_for_period period_start, period_end, min_volume = 100

    #Activity in OMEIN
    user_omein_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at between ? and ?", 
                                                        "OMEIN", period_start, period_end)

    omein_volume = 0
    user_omein_orders.each do |omein_order|
      omein_order.items.each do |item|
        omein_volume += item.volume
      end
    end

    if omein_volume < min_volume
      return false
    else
      return true
    end
    
  end

  #TODO: verify registration_paid in PRANA by checking ODERS with item 'INSCRIPCION' and adding a field in users named registration_paid
  def prana_active_for_period period_start, period_end, verify_min_volume_in_omein = false 

    #Activity in PRANA
    user_prana_orders = self.orders.joins(:items).where("items.company = ? AND orders.created_at between ? and ?", 
                                                        "PRANA", period_start, period_end)

    has_product_orders = Order.has_product_orders user_prana_orders

    if not has_product_orders
      return false
    end

    if (user_prana_orders.count > 0)

      if verify_min_volume_in_omein
        return self.omein_active_for_period period_start, period_end, 200
      else 
        return true
      end

    else
      return false      
    end 

  end

  def self.prana_check_activity_recursive_downline inactive_downline, period_start, period_end
    
    downlines = inactive_downline.placement_downlines 

    if downlines.count == 0
      return nil
    else
      inactive_downlines = []
      downlines.each do |downline|

        active_in_period = downline.prana_active_for_period period_start, period_end, false

        if active_in_period
          return downline
        else
          inactive_downlines << downline
        end
      end

      inactive_downlines.each do |inactive_downline|
        downline = User.prana_check_activity_recursive_downline inactive_downline, period_start, period_end
        if downline
          return downline
        end
      end

      return nil
      
    end

  end

  #TODO: Check upline activity based on Omein's orders
  def self.prana_check_activity_recursive_upline_3_levels upline, active_uplines, period_start, period_end

    if active_uplines.count == 3
      return active_uplines
    else

      active_in_period = upline.prana_active_for_period period_start, period_end, true

      if active_in_period 
        active_uplines << upline
      end
        
      if upline.placement_upline
        return User.prana_check_activity_recursive_upline_3_levels upline.placement_upline, active_uplines, period_start, period_end
      else
        return active_uplines
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
  
end
