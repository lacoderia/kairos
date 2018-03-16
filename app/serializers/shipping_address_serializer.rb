class ShippingAddressSerializer < ActiveModel::Serializer
  attributes :id, :address, :state, :location, :zip, :country
end
