FactoryBot.define do

  factory :order, class: Order do
    description 'test order'
    users {[FactoryBot.create(:user)]}

    before(:create) do |order|
      (0..3).each do
        item = FactoryBot.create(:item)
        order.items << item
      end
    end

    trait :with_address do
      shipping_address {FactoryBot.create(:shipping_address)}
    end
  end

end
