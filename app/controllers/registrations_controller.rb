class RegistrationsController < Devise::RegistrationsController
  include ErrorSerializer

  authorize_resource :class => false

  before_action :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation, :external_id, :sponsor_external_id, :placement_external_id, :active, :phone, :transaction_number])
  end

  def create
    
    if (current_user)
      sign_out current_user
    end

    build_resource(sign_up_params)
    @user = resource
    saved = @user.register(params[:token])
    
    if saved
      @user.save
      #SendEmailJob.perform_later("welcome", @user, nil)
      new_auth_header = @user.create_new_auth_token
      response.headers.merge!(new_auth_header)
      sign_in @user
      render json: @user
    else
      @user.errors.add(:incorrect_registration, "No se pudo crear el usuario.")
      render json: ErrorSerializer.serialize(@user.errors), status: 500
    end
  end
    
end
