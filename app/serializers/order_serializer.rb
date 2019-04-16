class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :order_number, :total_item_price, :total_item_volume
  has_many :items
  belongs_to :shipping_address

  def total_item_price
    object.total_item_price
  end

  def total_item_volume
    object.total_item_volume
  end
  
end
