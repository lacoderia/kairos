class Order < ApplicationRecord
  has_and_belongs_to_many :users
  has_and_belongs_to_many :items
  
  validates :items, presence: true

  after_create :update_summary_with_uplines

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :items, allow_destroy: true

  def self.get_volume_detail orders_with_items

    result = {items: []}
    total_volume = 0
    orders_with_items.each do |order|
      order.items.each do |item|
        result[:items] << {id: item.id, volume: item.volume}
        total_volume += item.volume
      end
    end

    result[:total_volume] = total_volume
    return result

  end

  def self.get_volume_detail_avoid_first_order orders_with_items

    result = {items: []}
    if orders_with_items.count > 1

      total_volume = 0
      first_order = true
      
      orders_with_items.order(created_at: :asc).each do |omein_order|

        if first_order 
          first_order = false
          next
        end
        
        omein_order.items.each do |item|
          result[:items] << {id: item.id, volume: item.volume}
          total_volume += item.volume
        end
      end

      result[:total_volume] = total_volume

    else
      result[:total_volume] = 0 
    end

    return result

  end

  def destroy
    user = self.users.first
    company = self.items.first.company
    period_start = self.created_at.beginning_of_month.strftime("%Y-%m-%d")
    period_end = (self.created_at.beginning_of_month + 1.month).strftime("%Y-%m-%d")
    super
    UpdateVolumeJob.perform_later(user, {period_start: period_start, period_end: period_end, company: company}) 
  end
  
  private

  def update_summary_with_uplines
    user = self.users.first
    company = self.items.first.company
    period_start = self.created_at.beginning_of_month.strftime("%Y-%m-%d")
    period_end = (self.created_at.beginning_of_month + 1.month).strftime("%Y-%m-%d")
    UpdateVolumeJob.perform_later(user, {period_start: period_start, period_end: period_end, company: company}) 
  end

end
