class Order < ApplicationRecord
  
  has_and_belongs_to_many :users
  has_and_belongs_to_many :items

  belongs_to :shipping_address, optional: true
  belongs_to :order, optional: true
  
  validates :items, presence: true

  after_create :generate_order_number_and_calculate_prices, :send_order_email, :update_summary_with_uplines

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :items, allow_destroy: true
  
  scope :prana, -> {joins(:items).where("items.company = '#{PranaCompPlan::COMPANY_PRANA}'").order(created_at: :desc).distinct} 
  scope :omein, -> {joins(:items).where("items.company = '#{OmeinCompPlan::COMPANY_OMEIN}'").order(created_at: :desc).distinct}
  scope :processed, -> {where(order_status: 'PROCESSED')}   
  scope :validating, -> {where(order_status: 'VALIDATING')}

  before_validation(on: :create) do
    if self.order_status.nil?
      self.update_attribute('order_status', 'PROCESSED')
    end
  end

  STATUSES = [
    'VALIDATING',
    'PROCESSED'
  ]

  validates :order_status, inclusion: {in: STATUSES}

  state_machine :order_status, initial: 'VALIDATING' do
    transition 'VALIDATING' => 'PROCESSED', on: :process
  end

  def self.all_for_user user, company
    company = OpenpayHelper.validate_company(company)    
    user.orders.processed.method(company.downcase).call
  end

  def self.validate_charge_and_redirect user, total, items, company, shipping_address_id, card_token, device_session_id

    amount_verify = 0
    item_array = []

    items.each do |item_hash|
      item = Item.find(item_hash["id"])
      amount = item_hash["amount"].to_i
      amount_verify += (item.price * amount)
      (0...amount).each do
        item_array << item
      end
    end

    shipping_price = {}
    if shipping_address_id
      shipping_price = Order.calculate_shipping_price(user, items, shipping_address_id)
      amount_verify += shipping_price[:shipping_price]
    end

    if amount_verify != total.to_f
      raise "El total de la orden no concuerda con la suma de los productos y su costo de envío"
    end 
 
    if shipping_address_id
      shipping_address = ShippingAddress.find(shipping_address_id)

      if not user.shipping_addresses.include?(shipping_address)
        raise "La dirección de la orden no está registrada en las direcciones del usuario"
      end
    else
      shipping_address = nil
    end

    company = OpenpayHelper.validate_company(company)    
    payment_api = OpenpayHelper.new(company)
    
    order_number = "#{Time.zone.now.to_formatted_s(:number)[2..13]}-#{user.external_id}"
    description = "Compra de orden en línea - #{order_number}"
   
    if company == PranaCompPlan::COMPANY_PRANA 
      redirect_url = Rails.application.secrets.prana_openpay_redirect_url
    elsif company == OmeinCompPlan::COMPANY_OMEIN
      redirect_url = Rails.application.secrets.omein_openpay_redirect_url
    else
      raise "Error encontrando compañía correcta"
    end

    charge_hash = payment_api.charge(user.get_openpay_id(company), card_token, total, nil, description, 
                                     device_session_id, redirect_url)    
    
    order = Order.create!(users: [user], description: description, order_number: order_number, openpay_id: charge_hash["id"], company: company, items: item_array, shipping_address: shipping_address, order_status: "VALIDATING", redirect_url: charge_hash["payment_method"]["url"], shipping_price: shipping_price[:shipping_price]) 

    return order

  end

  def self.verify_and_apply_fee user, openpay_id

    order = Order.find_by_openpay_id(openpay_id)

    if order

      # verify order in openpay
      company = OpenpayHelper.validate_company(order.company)    
      payment_api = OpenpayHelper.new(company)

      order_hash = payment_api.get_transaction(user.get_openpay_id(company), order.openpay_id)

      if order_hash["status"] == "completed"
    
        if order.shipping_address
          shipping_price = order.calculate_shipping_price      
          order_id = nil
          if shipping_price[:paired_order] == "self"
            order.update_column("order_id", order.id)
          elsif shipping_price[:paired_order] != "none"
            order.update_column("order_id", shipping_price[:paired_order])
            #pair the order
            Order.find(shipping_price[:paired_order]).update_column(:order_id, order.id)
          #else
            #order.update_column(:shipping_price, shipping_price[:shipping_price])
          end
        end
      
        order.process 
        #background jobs
        SendEmailJob.perform_later("order", order.users.first, order) 
        SendEmailJob.perform_later("process_order", order.users.first, order) 
        order.update_volume_for_users
        ChargeFeeJob.perform_later(user, company, order)
      
        return order

      else
        raise "La orden no fue completada con éxito - #{order_hash["status"]}"
      end

    else 
      raise "La orden no pudo ser encontrada."
    end

  end


  def self.create_with_items user, total, items, company, shipping_address_id, card_token, device_session_id

    amount_verify = 0
    item_array = []

    items.each do |item_hash|
      item = Item.find(item_hash["id"])
      amount = item_hash["amount"].to_i
      amount_verify += (item.price * amount)
      (0...amount).each do
        item_array << item
      end
    end

    if shipping_address_id
      shipping_price = Order.calculate_shipping_price(user, items, shipping_address_id)
      amount_verify += shipping_price[:shipping_price]
    end

    if amount_verify != total.to_f
      raise "El total de la orden no concuerda con la suma de los productos y su costo de envío"
    end 
 
    if shipping_address_id
      shipping_address = ShippingAddress.find(shipping_address_id)

      if not user.shipping_addresses.include?(shipping_address)
        raise "La dirección de la orden no está registrada en las direcciones del usuario"
      end
    else
      shipping_address = nil
    end
    
    company = OpenpayHelper.validate_company(company)    
    payment_api = OpenpayHelper.new(company)
    
    order_number = "#{Time.zone.now.to_formatted_s(:number)[2..13]}-#{user.external_id}"
    description = "Compra de orden en línea - #{order_number}"
    
    charge_hash = payment_api.charge(user.get_openpay_id(company), card_token, total, nil, description, device_session_id)
    charge_fee_hash = payment_api.charge_fee(user.get_openpay_id(company), total, description, nil)
      
    order = Order.create!(users: [user], description: description, order_number: order_number, 
                          items: item_array, shipping_address: shipping_address)

    if shipping_address_id 
      order_id = nil
      if shipping_price[:paired_order] == "self"
        order.update_columns({order_id: order.id, shipping_price: shipping_price[:shipping_price]})
      elsif shipping_price[:paired_order] == "none"
        order.update_column(:shipping_price, shipping_price[:shipping_price])
      else
        order.update_columns({order_id: shipping_price[:paired_order], shipping_price: shipping_price[:shipping_price]})
        #pair the order
        Order.find(shipping_price[:paired_order]).update_column(:order_id, order.id)
      end

    end
      
    return order
  end

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
      
      orders_with_items.sort_by{|order| order.created_at}.each do |omein_order|

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

  def total_item_price
    self.items.sum do |item|
      item.price
    end
  end

  def total_item_volume
    self.items.sum do |item|
      item.volume
    end
  end

  def calculate_total_price
    item_price = self.total_item_price
    if self.shipping_price
      return item_price + self.shipping_price
    else
      return item_price
    end
  end

  def self.shipping_price_helper user, shipping_address_id, total_item_volume

    packages_count = total_item_volume/Config.max_volume_per_order
    
    if total_item_volume%Config.max_volume_per_order > 0
      packages_count += 1
    end

    if packages_count.even?
      paired_packages = packages_count/2
      shipping_price = paired_packages * Config.shipping_price_per_2_orders 
      return {shipping_price: shipping_price, paired_order: "self", message: "El precio de envío a esta dirección es de $#{printf("%.2f", Config.shipping_price_per_2_orders)} por cada #{Config.max_volume_per_order*2} puntos."}
    else
      shipping_price = Config.shipping_price_per_order

      if packages_count != 1
        paired_package_price = (packages_count/2) * Config.shipping_price_per_2_orders
        shipping_price += paired_package_price 
      end

      # sent to the same shipping address, and that isn't paired with any other order
      previous_orders = user.orders.where("created_at >= ? AND created_at <= ? AND shipping_address_id = ? AND orders.order_id IS NULL AND orders.order_status != ?", Time.zone.now.beginning_of_day, Time.zone.now.end_of_day, shipping_address_id, "VALIDATING")

      # in theory, there will be only one or no previous_orders that are not paired
      #if previous_orders.count > 1
      #  raise 'Existe más de una orden que no ha sido emparejada para aprovechar el envío.'
      #end
      
      # order to pair with
      if previous_orders.count >= 1

        if packages_count == 1
          shipping_price = (Config.shipping_price_per_2_orders - Config.shipping_price_per_order)
          return {shipping_price: shipping_price, paired_order: previous_orders.first.id, message: "El precio de envío de $#{printf("%.2f", shipping_price)} considera que hoy ya se pagó a esta misma dirección la cantidad de $#{printf("%.2f", previous_orders.first.shipping_price)} por el pedido #{previous_orders.first.order_number}."}
        else
          #delta because one has already been paid
          shipping_price += (Config.shipping_price_per_2_orders - Config.shipping_price_per_order)
          return {shipping_price: shipping_price, paired_order: previous_orders.first.id, message: "El precio de envío de $#{printf("%.2f", shipping_price)} considera que hoy ya se pagó a esta misma dirección la cantidad de $#{printf("%.2f", previous_orders.first.shipping_price)} por el pedido #{previous_orders.first.order_number}."}
        end

      # no other orders to pair with
      else
        return {shipping_price: shipping_price, paired_order: "none", message: "El precio de envío a esta dirección es de $#{printf("%.2f", Config.shipping_price_per_order)} hasta #{Config.max_volume_per_order} puntos." }
      end

    end

  end

  def calculate_shipping_price

    if self.shipping_address.nil?
      return {shipping_price: 0, paired_order: "none", message: "Recoger en tienda no incurre en costos de envío."}
    end

    total_item_volume = 0
    items.each do |item|
      total_item_volume += item.volume
    end

    return Order.shipping_price_helper self.users.first, self.shipping_address.id, total_item_volume     

  end

  def self.calculate_shipping_price(user, items_hash, shipping_address_id)

    if not shipping_address_id
      return {shipping_price: 0, paired_order: "none", message: "Recoger en tienda no incurre en costos de envío"}
    end

    total_item_volume = 0
    items_hash.each do |ih|
      item = Item.find(ih["id"])
      amount = ih["amount"].to_i
      total_item_volume += (item.volume * amount)
    end

    return Order.shipping_price_helper user, shipping_address_id, total_item_volume         

  end

  def update_volume_for_users
    user = self.users.first
    company = self.items.first.company
    period_start = self.created_at.beginning_of_month.strftime("%Y-%m-%d")
    period_end = (self.created_at.beginning_of_month + 1.month).strftime("%Y-%m-%d")
    UpdateVolumeJob.perform_later(user, {period_start: period_start, period_end: period_end, company: company})
  end

  def compact_items
    items_hash = {}
    
    self.items.each do |item|
      if items_hash[item.id] 
        items_hash[item.id][:amount] = items_hash[item.id][:amount] + 1
      else
        items_hash[item.id] = item.attributes
        items_hash[item.id][:image] = item.image_url 
        items_hash[item.id][:amount] = 1
      end
    end

    items_array = []
    items_hash.each do |key, value|
      items_array << value
    end
    return items_array
  end
  
  private

  def update_summary_with_uplines
    if self.order_status == "PROCESSED"    
      self.update_volume_for_users
    end
  end

  def generate_order_number_and_calculate_prices
    if self.order_number.blank?
      self.update_column(:order_number, "#{Time.zone.now.to_formatted_s(:number)[2..13]}-#{self.users.first.external_id}") 
    end
    self.update_column(:total_price, self.calculate_total_price)
  end

  def send_order_email
    if self.order_status == "PROCESSED"
      SendEmailJob.perform_later("order", self.users.first, self) 
    end
  end

end
