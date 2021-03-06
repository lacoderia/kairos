class ShippingAddress < ApplicationRecord
  has_and_belongs_to_many :users  
  has_many :orders

  scope :by_user_id, -> (user_id){joins(:users).where("shipping_addresses_users.user_id = ?", user_id)}
  scope :available, -> {where("active = ?", true)}
  
  def to_s
    "#{self.address}, #{self.state} #{self.city}, #{self.zip} #{self.country}"
  end

  def to_s_with_reference
    "#{self.address}, #{self.state} #{self.city}, #{self.zip} #{self.country},\n nombre de quien recibe: #{self.name}, teléfono: #{self.phone}, referencia: #{self.reference}, entre calles: #{self.between_streets}"
  end

  def deactivate
    self.update_attribute("active", false)
    return self
  end
  
end
