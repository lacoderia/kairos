FactoryBot.define do

  factory :email, class: Email do
    association :user, factory: :user
    email_status
    email_type
  end
  
end
