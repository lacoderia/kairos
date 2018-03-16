class ApiController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken 
  respond_to :json

  def authenticate_user!
    if user_signed_in?
      super
    else
      user = User.new
      user.errors.add(:error_authenticating, "Error autenticando encabezados.")
      render json: ErrorSerializer.serialize(user.errors), status: 500
    end
  end
end

