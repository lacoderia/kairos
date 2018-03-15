class InvitationSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :recipient_name, :recipient_email, :token, :used
end
