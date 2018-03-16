FactoryBot.define do
  
  factory :user, class: User do
    sequence(:email){ |n| "user-#{n}@prana.mx" }
    first_name 'Test'
    last_name 'User'
    password '12345678'
    password_confirmation '12345678'
    sequence(:phone){ |n| "555555555#{n}" }
    roles {[FactoryBot.create(:role)]}
    sequence(:external_id){|n| n+1 }
    sequence(:sponsor_external_id){|n| n}
    sequence(:placement_external_id){|n| n }
    
    trait :with_address do
      addresses {[FactoryBot.create(:address)]}
    end
  end

end
