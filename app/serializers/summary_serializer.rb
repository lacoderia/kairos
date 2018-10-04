class SummarySerializer < ActiveModel::Serializer
  attributes :current_month, :previous_month, :ranks
end
