class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :order_number, :total_item_price, :total_item_volume, :total_price, :shipping_price, :items, :created_at
#  has_many :items
  belongs_to :order
  belongs_to :shipping_address

  def total_item_price
    object.total_item_price
  end

  def total_item_volume
    object.total_item_volume
  end

  def total_price
    if object.total_price
      object.total_price
    else
      #for previous orders without total_price
      object.calculate_total_price
    end
  end

  def items
    object.compact_items
  end
  
end
