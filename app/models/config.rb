class Config < ActiveRecord::Base

  DEFAULT_MAX_VOLUME_PER_ORDER = 210
  DEFAULT_SHIPPING_PRICE_PER_ORDER = 180
  DEFAULT_SHIPPING_PRICE_PER_2_ORDERS = 250
  DEFAULT_ORDER_NOTIFICATION_EMAIL = "servicioalcliente@omein.com"

   def self.max_volume_per_order
    max_volume_per_order = Config.find_by_key("max_volume_per_order")
    if max_volume_per_order
      begin
        return max_volume_per_order.value.to_i
      rescue Exception => e
        return DEFAULT_MAX_VOLUME_PER_ORDER
      end
    else
      return DEFAULT_MAX_VOLUME_PER_ORDER
    end
  end

   def self.shipping_price_per_order
    shipping_price_per_order = Config.find_by_key("shipping_price_per_order")
    if shipping_price_per_order
      begin
        return shipping_price_per_order.value.to_f
      rescue Exception => e
        return DEFAULT_SHIPPING_PRICE_PER_ORDER
      end
    else
      return DEFAULT_SHIPPING_PRICE_PER_ORDER
    end
   end

   def self.shipping_price_per_2_orders
    shipping_price_per_2_orders = Config.find_by_key("shipping_price_per_2_orders")
    if shipping_price_per_2_orders
      begin
        return shipping_price_per_2_orders.value.to_f
      rescue Exception => e
        return DEFAULT_SHIPPING_PRICE_PER_2_ORDERS
      end
    else
      return DEFAULT_SHIPPING_PRICE_PER_2_ORDERS
    end
   end

   def self.order_notification_email
    order_notification_email = Config.find_by_key("order_notification_email")
    if  order_notification_email
      begin
        return order_notification_email.value
      rescue Exception => e
        return DEFAULT_ORDER_NOTIFICATION_EMAIL
      end
    else
      return DEFAULT_ORDER_NOTIFICATION_EMAIL
    end
   end

end
