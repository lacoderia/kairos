class ItemsController < ApiController

  load_and_authorize_resource
  before_action :authenticate_user!

  def by_company 
    begin
      company = OpenpayHelper.validate_company(params[:company])
      @items = Item.by_company(company)
      render json: @items
    rescue Exception => e
      @item = Item.new
      @item.errors.add(:error_getting_items, e.message)
      render json: ErrorSerializer.serialize(@item.errors), status: 500
    end
  end

end
