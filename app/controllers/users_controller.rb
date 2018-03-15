class UsersController < ApiController
  include ErrorSerializer
  
  before_action :authenticate_user!
  before_action :set_user, only: [:update]  

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    if @user.update(user_params)
      if user_params[:password]
        signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
        sign_in(@user)
      end
      render json: @user
    else
      render json: ErrorSerializer.serialize(@user.errors)
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :external_id, :iuvare_id, :sponsor_external_id, :placement_external_id, :active, :phone, :password , :password_confirmation)
    end
  
end
