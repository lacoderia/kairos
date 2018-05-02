class PaymentSerializer < ActiveModel::Serializer
  attributes :id, :amount, :payment_type, :term_paid
end
