class ConfirmationsController < Devise::ConfirmationsController

  # POST /auth/confirmation
  def create

    begin
      email = params[:user][:email]
      @user = User.find_by_email(email)

      if @user
        @user.send_confirmation_instructions
        render json: @user
      else
        @user = User.new
        @user.errors.add(:no_user_confirmation, "No se contró un usuario asociado a ese correo electrónico.")
        render json: ErrorSerializer.serialize(@user.errors), status: 500
      end
    rescue Exception => e 
      @user = User.new
      @user.errors.add(:confirmation-error, "Hubo un error enviando la confirmación al correo electrónico.")
      render json: ErrorSerializer.serialize(@user.errors), status: 500
    end

  end

end 
