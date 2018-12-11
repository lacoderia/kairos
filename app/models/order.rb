class Order < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :items
  
  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :items, allow_destroy: true

  def self.get_volume_detail orders_with_items

    result = {items: []}
    total_volume = 0
    orders_with_items.each do |order|
      order.items.each do |item|
        result[:items] << {id: item.id, volume: item.volume}
        total_volume += item.volume
      end
    end

    result[:total_volume] = total_volume
    return result

  end

  def self.get_volume_detail_avoid_first_order orders_with_items

    result = {items: []}
    if orders_with_items.count > 1

      total_volume = 0
      first_order = true
      
      orders_with_items.order(created_at: :asc).each do |omein_order|

        if first_order 
          first_order = false
          next
        end
        
        omein_order.items.each do |item|
          result[:items] << {id: item.id, volume: item.volume}
          total_volume += item.volume
        end
      end

      result[:total_volume] = total_volume

    else
      result[:total_volume] = 0 
    end

    return result

  end

end
