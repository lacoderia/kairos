class ShippingAddress < ApplicationRecord
  has_and_belongs_to_many :users  
  has_many :orders

  scope :by_user_id, -> (user_id){joins(:users).where("shipping_addresses_users.user_id = ?", user_id)}
  
end
