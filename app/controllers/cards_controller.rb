class CardsController < ApiController
  
  load_and_authorize_resource
  before_action :authenticate_user!, except: [:get_device_session_id]

  ActiveRecord::Base.include_root_in_json = false

  def create
    begin
      @card = Card.create_for_user(current_user, params[:token], params[:device_session_id], params[:company])
      render json: @card
    rescue Exception => e
      @card = Card.new
      @card.errors.add(:error_generating_openpay_card, e.message)
      render json: ErrorSerializer.serialize(@card.errors), status: 500
    end    
  end

  def delete
    begin
      @cards_left = Card.delete_for_user(current_user, params[:id], params[:company])
      render json: @cards_left  
    rescue Exception => e
      @card = Card.new
      @card.errors.add(:error_deleting_openpay_card, e.message)
      render json: ErrorSerializer.serialize(@card.errors), status: 500
    end    
  end

  def set_primary
    begin
      @card = Card.set_primary_for_user(current_user, params[:id], params[:company])
      render json: @card
    rescue Exception => e
      @card = Card.new
      @card.errors.add(:error_marking_card_as_primary, e.message)
      render json: ErrorSerializer.serialize(@card.errors), status: 500
    end
  end

  def all
    begin
      @cards = Card.get_all_for_user(current_user, params[:company])
      render json: @cards
    rescue Exception => e
      @card = Card.new
      @card.errors.add(:error_getting_all_cards_for_user, e.message)
      render json: ErrorSerializer.serialize(@card.errors), status: 500
    end
  end

  def get_device_session_id
  end

  private

  def card_params
    params.require(:card).permit(:company)
  end

end
