FactoryBot.define do
  
  factory :user, class: User do
    sequence(:email){ |n| "user-#{n}@prana.mx" }
    first_name 'Test'
    last_name 'User'
    password '12345678'
    password_confirmation '12345678'
    sequence(:phone){ |n| "555555555#{n}" }
    roles {[FactoryBot.create(:role)]}
  end

end
