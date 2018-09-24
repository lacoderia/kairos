class ShippingAddressSerializer < ActiveModel::Serializer
  attributes :id, :address, :state, :location, :zip, :city, :country
end
