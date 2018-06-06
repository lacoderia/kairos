class ItemSerializer < ActiveModel::Serializer
  attributes :id, :company, :name, :description, :price, :commissionable_value, :volume
end
