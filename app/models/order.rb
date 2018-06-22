class Order < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :items

  def self.has_product_orders user_prana_orders

    user_prana_orders.each do |prana_order|
      prana_order.items.each do |item|
        if item.name != "INSCRIPCION"
          return true
        end
      end
    end

    return false
        
  end
end
