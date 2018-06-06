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

  def self.check_activity_recursive_downline inactive_downline, period
    
    downlines = inactive_downline.placement_downlines 

    if downlines.count == 0
      return nil
    else
      inactive_downlines = []
      downlines.each do |downline|
        orders_in_period = downline.orders.where("description = ?", period).count
        if orders_in_period > 0
          return downline
        else
          inactive_downlines << downline
        end
      end

      inactive_downlines.each do |inactive_downline|
        downline = User.check_activity_recursive_downline inactive_downline, period
        if downline
          return downline
        end
      end

      return nil
      
    end

  end

  def self.check_activity_recursive_upline_3_levels upline, active_uplines, period


    if active_uplines.count == 3
      return active_uplines
    else
      orders_in_period = upline.orders.where("description = ?", period).count

      if orders_in_period > 0
        active_uplines << upline
      end
        
      if upline.placement_upline
        return User.check_activity_recursive_upline_3_levels upline.placement_upline, active_uplines, period
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
        puts "Árbol sin upline para el usuario con ID #{user.external_id}"
        return false
      end

    end


  end
  
end
