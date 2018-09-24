FactoryBot.define do

  factory :shipping_address, class: ShippingAddress do
    address "Test Address"
    state "Test State"
    location "TL"
    zip "03344"
    country "Test Country"
    city "Test City"
  end
  
end
