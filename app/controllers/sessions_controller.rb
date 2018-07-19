class SessionsController < Devise::SessionsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ErrorSerializer

  authorize_resource :class => false

  def create
    
    @user = User.find_by_email(params[:user][:email])
    if @user
      if @user.valid_password?(params[:user][:password])

        if @user.confirmed?
          new_auth_header = @user.create_new_auth_token
          response.headers.merge!(new_auth_header)
          sign_in @user
          render json: @user
        else
          @user.errors.add(:unconfirmed_email, "El correo electrónico no ha sido confirmado.")
          render json: ErrorSerializer.serialize(@user.errors), status: 500
        end
      else
        @user.errors.add(:incorrect_login, "El correo electrónico o la contraseña son incorrectos.")
        render json: ErrorSerializer.serialize(@user.errors), status: 500
      end
    else
      @user = User.new
      @user.errors.add(:incorrect_login, "El correo electrónico o la contraseña son incorrectos.")
      render json: ErrorSerializer.serialize(@user.errors), status: 500
    end
  end

  def get
    if current_user
      @user = current_user
      render json: @user
    else
      @user = User.new
      @user.errors.add(:no_session, "No se ha iniciado sesión.")
      render json: ErrorSerializer.serialize(@user.errors), status: 500
    end
  end

end

