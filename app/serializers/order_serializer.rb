class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :order_number, :total_price, :total_volume
  has_many :items
  belongs_to :shipping_address

  def total_price
    object.total_price
  end

  def total_volume
    object.total_volume
  end
  
end
