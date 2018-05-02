class OrderSerializer < ActiveModel::Serializer
  attributes :id, :description, :item_id
end
