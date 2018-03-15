FactoryBot.define do

  factory :invitation, class: Invitation do
    association :user, factory: :user
    recipient_name "Recipient First Name"
    sequence(:recipient_email){ |n| "user-#{n}@whatever.mx" }
    sequence(:token){ |n| "token-string-#{n}" }
  end

end
