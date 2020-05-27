class SessionsController < Devise::SessionsController
  include DeviseTokenAuth::Concerns::SetUserByToken

  authorize_resource :class => false

  def create
    
    @user = User.find_by_email(params[:user][:email])
    if @user
      if @user.valid_password?(params[:user][:password])

        if @user.confirmed?
          if not @user.active
            @user = User.new
            @user.errors.add(:inactive_user, "No puedes iniciar sesión, tu usuario está inactivo.")
            render json: ErrorSerializer.serialize(@user.errors), status: 500            
          else
            new_auth_header = @user.create_new_auth_token
            response.headers.merge!(new_auth_header)
            sign_in @user
            render json: @user
          end

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
      if not current_user.active
        @user = User.new
        @user.errors.add(:inactive_user, "No puedes iniciar sesión, tu usuario está inactivo.")
        render json: ErrorSerializer.serialize(@user.errors), status: 500            
      else
        @user = current_user
        render json: @user
      end
    else
      @user = User.new
      @user.errors.add(:no_session, "No se ha iniciado sesión.")
      render json: ErrorSerializer.serialize(@user.errors), status: 500
    end
  end

end

