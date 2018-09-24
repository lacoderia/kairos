class ShippingAddressesController < ApiController
  include ErrorSerializer
  
  load_and_authorize_resource
  before_action :authenticate_user!
  before_action :set_shipping_address, only: [:update, :destroy] 

  # POST /shipping_addresses
  def create
    begin
      @shipping_address = ShippingAddress.create!(shipping_address_params)
      current_user.shipping_addresses << @shipping_address
      render json: @shipping_address
    rescue Exception => e
      @shipping_address = ShippingAddress.new
      @shipping_address.errors.add(:error_creating_shipping_address, e.message)
      render json: ErrorSerializer.serialize(@shipping_address.errors), status: 500
    end
  end

  # PATCH/PUT /shipping_addresses/[id]
  def update
    if @shipping_address.update(shipping_address_params)
      render json: @shipping_address
    else
      render json: ErrorSerializer.serialize(@shipping_address.errors), status: 500
    end
  end

  # GET /shipping_addresses/get_all_for_user
  def get_all_for_user

    begin
      @shipping_addresses = current_user.shipping_addresses
      render json: @shipping_addresses
    rescue Exception => e
      @shipping_address = ShippingAddress.new
      @shipping_address.errors.add(:error_getting_shipping_addresses, "Error obteniendo direcciones para el usuario")
      render json: ErrorSerializer.serialize(@shipping_address.errors), status: 500
    end

  end

  def destroy
    begin
      @shipping_address.destroy
      render json: @shipping_addresses
    rescue Exception => e
      @shipping_address = ShippingAddress.new
      @shipping_address.errors.add(:error_deleting_shipping_address, e.message)
      render json: ErrorSerializer.serialize(@shipping_address.errors), status: 500
    end
  end

  private

    def set_shipping_address
      @shipping_address = ShippingAddress.find(params[:id])
    end

    def shipping_address_params
      params.require(:shipping_address).permit(:location, :address, :state, :country, :zip, :city)
    end
  
end
