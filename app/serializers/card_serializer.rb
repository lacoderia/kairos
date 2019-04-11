class CardSerializer < ActiveModel::Serializer
  attributes :id, :openpay_id, :active, :user_id, :primary, :holder_name, :card_number, :expiration, :brand, :company
end
