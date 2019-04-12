FactoryBot.define do

  factory :item, class: Item do

    name 'Test product'
    description 'Test description'
    price 100.0
    commissionable_value 90.0
    volume 100
    company 'PRANA' 
    active true

  end

end
