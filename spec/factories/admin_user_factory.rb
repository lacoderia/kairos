FactoryBot.define do

  factory :admin_user, class: AdminUser do
    sequence(:email){ |n| "admin-#{n}@kairos.mx" }
    password "password"
    password_confirmation "password"
  end

end
