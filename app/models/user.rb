class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable#, :confirmable
  
  include DeviseTokenAuth::Concerns::User

  has_and_belongs_to_many :roles  
  has_and_belongs_to_many :shipping_addresses
  has_many :emails
  has_many :invitations

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
  
end
