class OrdersController < ApiController

  # GET /orders/all
  def all
     begin
      @orders = Order.all_for_user current_user, params[:company]
      render json: @orders, include: [:items, :shipping_address]
    rescue Exception => e
      @order = Order.new
      @order.errors.add(:error_getting_orders_for_user, "Error obteniendo las órdenes del usuario")
      render json: ErrorSerializer.serialize(@order.errors), status: 500
    end
  end

   # POST /orders/create_with_items
  def create_with_items
    begin
      @order = Order.create_with_items(current_user, params[:total], params[:items], params[:company], params[:shipping_address_id],
                                       params[:card_id], params[:device_session_id])
      render json: @order, include: [:items, :shipping_address]
    rescue Exception => e
      @order = Order.new
      @order.errors.add(:error_creating_order, "Error creando la orden. #{e.message}")
      render json: ErrorSerializer.serialize(@order.errors), status: 500
    end
  end 

  # POST /orders/calculate_shipping_price
  def calculate_shipping_price
    begin
      shipping_price = Order.calculate_shipping_price(current_user, params[:items], params[:shipping_address_id])
      render json: ShippingPriceSerializer.serialize(shipping_price)
    rescue => e
      @order = Order.new
      @order.errors.add(:error_calculating_shipping_price, "Error obteniendo el precio de envío.")
      render json: ErrorSerializer.serialize(@order.errors), status: 500
    end
  end

  private

  def order_params
    params.require(:order).permit(:shipping_address_id)
  end

end
