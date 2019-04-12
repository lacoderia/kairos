class Item < ApplicationRecord
  has_and_belongs_to_many :orders
  mount_uploader :image, ItemUploader  

  scope :by_company, -> (company){where(company: company)}
end
