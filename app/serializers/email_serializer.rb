class EmailSerializer < ActiveModel::Serializer
  attributes :id, :references, :email_status, :email_type
end
