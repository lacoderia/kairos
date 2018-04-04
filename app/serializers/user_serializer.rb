class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :external_id, :sponsor_external_id, :placement_external_id, :phone, :active, :email, :transaction_number, :iuvare_id
end
