class ShippingAddressSerializer < ActiveModel::Serializer
  attributes :id, :address, :state, :location, :zip, :city, :country, :active, :name, :phone, :reference, :between_streets
end
